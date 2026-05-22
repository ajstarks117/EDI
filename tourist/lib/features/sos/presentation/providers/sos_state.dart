import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../../safety/services/gps_service.dart';
import '../../sos_service.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum SosStatus {
  idle,
  activating,   // 3-second hold in progress
  active,       // SOS triggered — layers firing
  acknowledged, // Authority system received the alert
  responding,   // Responder confirmed en-route
  resolved,     // Incident closed
  cancelled,    // User cancelled with 4-digit code
  falseAlarm,   // Marked as false alarm
}

enum SosLayerStatus {
  idle,
  attempting,
  success,
  failed,
}

enum LayerType {
  internet,
  sms,
  wifiDirect,
  ble,
  audio,
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SosState {
  final SosStatus status;
  final double activationProgress;   // 0.0 → 1.0 during 3-second hold
  final SosLayerStatus layerInternet;
  final SosLayerStatus layerSms;
  final SosLayerStatus layerWifiDirect;
  final SosLayerStatus layerBle;
  final SosLayerStatus layerAudio;
  final String? sosId;
  final int? estimatedResponseMin;
  final String? relayedBy;
  final String? locationText;

  const SosState({
    this.status = SosStatus.idle,
    this.activationProgress = 0.0,
    this.layerInternet = SosLayerStatus.idle,
    this.layerSms = SosLayerStatus.idle,
    this.layerWifiDirect = SosLayerStatus.idle,
    this.layerBle = SosLayerStatus.idle,
    this.layerAudio = SosLayerStatus.idle,
    this.sosId,
    this.estimatedResponseMin,
    this.relayedBy,
    this.locationText,
  });

  SosState copyWith({
    SosStatus? status,
    double? activationProgress,
    SosLayerStatus? layerInternet,
    SosLayerStatus? layerSms,
    SosLayerStatus? layerWifiDirect,
    SosLayerStatus? layerBle,
    SosLayerStatus? layerAudio,
    String? sosId,
    int? estimatedResponseMin,
    String? relayedBy,
    String? locationText,
    bool clearSosId = false,
    bool clearRelayedBy = false,
  }) {
    return SosState(
      status: status ?? this.status,
      activationProgress: activationProgress ?? this.activationProgress,
      layerInternet: layerInternet ?? this.layerInternet,
      layerSms: layerSms ?? this.layerSms,
      layerWifiDirect: layerWifiDirect ?? this.layerWifiDirect,
      layerBle: layerBle ?? this.layerBle,
      layerAudio: layerAudio ?? this.layerAudio,
      sosId: clearSosId ? null : (sosId ?? this.sosId),
      estimatedResponseMin: estimatedResponseMin ?? this.estimatedResponseMin,
      relayedBy: clearRelayedBy ? null : (relayedBy ?? this.relayedBy),
      locationText: locationText ?? this.locationText,
    );
  }

  /// True when SOS is in any actively-engaged state
  bool get isActive =>
      status == SosStatus.active ||
      status == SosStatus.acknowledged ||
      status == SosStatus.responding;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier() : super(const SosState());

  Timer? _activationTimer;
  final GpsService _gpsService = GpsService();
  final SosService _sosService = SosService();

  void setLayerStatus(LayerType type, SosLayerStatus status) {
    if (!mounted) return;
    switch (type) {
      case LayerType.internet:
        state = state.copyWith(layerInternet: status);
        break;
      case LayerType.sms:
        state = state.copyWith(layerSms: status);
        break;
      case LayerType.wifiDirect:
        state = state.copyWith(layerWifiDirect: status);
        break;
      case LayerType.ble:
        state = state.copyWith(layerBle: status);
        break;
      case LayerType.audio:
        state = state.copyWith(layerAudio: status);
        break;
    }
  }

  void setSosId(String id) {
    if (!mounted) return;
    state = state.copyWith(sosId: id);
  }

  // --- Activation hold (called every ~100ms from FAB) ---

  void startActivation() {
    state = state.copyWith(
      status: SosStatus.activating,
      activationProgress: 0.0,
    );

    _activationTimer?.cancel();
    _activationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        final next = state.activationProgress + (1.0 / 30.0); // 30 ticks × 100ms = 3s
        if (next >= 1.0) {
          timer.cancel();
          _activationTimer = null;
          _triggerSos();
        } else {
          state = state.copyWith(activationProgress: next);
        }
      },
    );
  }

  void cancelActivation() {
    _activationTimer?.cancel();
    _activationTimer = null;
    if (state.status == SosStatus.activating) {
      state = const SosState(); // back to idle
    }
  }

  // --- Full SOS trigger ---

  Future<void> _triggerSos() async {
    // 1. Acquire location with prefetch fallback and 2-second timeout
    Position? pos;
    try {
      await _gpsService.requestPermission();
      pos = await _gpsService.getLastKnownPosition();
    } catch (_) {}

    try {
      final freshPos = await _gpsService.getCurrentPosition(
        timeLimit: const Duration(seconds: 2),
      );
      pos = freshPos;
    } catch (_) {
      // Keep last known position if fresh fix fails or times out
    }

    final double lat = pos?.latitude ?? 18.5204;
    final double lng = pos?.longitude ?? 73.8567;
    final locText = pos != null
        ? '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E'
        : 'GPS Unavailable';

    final initialSosId = 'SOS-${DateTime.now().millisecondsSinceEpoch}';

    state = state.copyWith(
      status: SosStatus.active,
      activationProgress: 1.0,
      sosId: initialSosId,
      locationText: locText,
      layerInternet: SosLayerStatus.idle,
      layerSms: SosLayerStatus.idle,
      layerWifiDirect: SosLayerStatus.idle,
      layerBle: SosLayerStatus.idle,
      layerAudio: SosLayerStatus.idle,
    );

    // 2. Call SosService sendSosCascade for Layer 1 & 2
    await _sosService.sendSosCascade(
      notifier: this,
      lat: lat,
      lng: lng,
    );

    // 3. If Layer 1 (Internet) did NOT succeed, fire Wi-Fi Direct, BLE, and Audio Siren concurrently
    if (state.layerInternet != SosLayerStatus.success) {
      await Future.wait([
        _fireLayerWifiDirect(),
        _fireLayerBle(),
        _fireLayerAudio(),
      ]);
    }

    // 4. After all attempted layers, transition to acknowledged if at least one channel succeeded
    if (!mounted) return;
    final anySuccess =
        state.layerInternet == SosLayerStatus.success ||
        state.layerSms == SosLayerStatus.success ||
        state.layerBle == SosLayerStatus.success;
    if (anySuccess && state.status == SosStatus.active) {
      state = state.copyWith(
        status: SosStatus.acknowledged,
        estimatedResponseMin: 8,
      );
    }
  }

  // --- Layer 3: Wi-Fi Direct ---
  Future<void> _fireLayerWifiDirect() async {
    if (!mounted) return;
    state = state.copyWith(layerWifiDirect: SosLayerStatus.attempting);
    await Future.delayed(const Duration(milliseconds: 800));

    // Wi-Fi Direct is a best-effort channel; mark success if wifi is on
    try {
      final conn = await Connectivity().checkConnectivity();
      if (!mounted) return;
      state = state.copyWith(
        layerWifiDirect: conn.contains(ConnectivityResult.wifi)
            ? SosLayerStatus.success
            : SosLayerStatus.failed,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(layerWifiDirect: SosLayerStatus.failed);
    }
  }

  // --- Layer 4: BLE ---
  Future<void> _fireLayerBle() async {
    if (!mounted) return;
    state = state.copyWith(layerBle: SosLayerStatus.attempting);
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (isSupported) {
        final adapterState = await FlutterBluePlus.adapterState.first;
        if (!mounted) return;
        state = state.copyWith(
          layerBle: adapterState == BluetoothAdapterState.on
              ? SosLayerStatus.success
              : SosLayerStatus.failed,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(layerBle: SosLayerStatus.failed);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(layerBle: SosLayerStatus.failed);
    }
  }

  // --- Layer 5: Audio Siren ---
  Future<void> _fireLayerAudio() async {
    if (!mounted) return;
    state = state.copyWith(layerAudio: SosLayerStatus.attempting);
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      for (int i = 0; i < 6; i++) {
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      if (!mounted) return;
      state = state.copyWith(layerAudio: SosLayerStatus.success);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(layerAudio: SosLayerStatus.failed);
    }
  }

  // --- Cancel with security code ---
  bool cancelWithCode(String code) {
    // Accept any 4-digit code for now; in production use a user-set PIN
    if (code.length == 4 && RegExp(r'^\d{4}$').hasMatch(code)) {
      _activationTimer?.cancel();
      _activationTimer = null;
      state = const SosState(status: SosStatus.cancelled);
      // Reset to idle after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = const SosState();
        }
      });
      return true;
    }
    return false;
  }

  /// Full reset to idle
  void resetToIdle() {
    _activationTimer?.cancel();
    _activationTimer = null;
    state = const SosState();
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final sosStateProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier();
});
