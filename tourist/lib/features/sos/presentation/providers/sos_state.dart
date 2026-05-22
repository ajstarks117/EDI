import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../safety/services/gps_service.dart';
import '../../sos_service.dart';
import '../../wifi_direct_sos_service.dart';
import '../../ble_sos_service.dart';
import '../../audio_morse_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/constants/app_constants.dart';

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
  final bool isBleAdvertising;

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
    this.isBleAdvertising = false,
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
    bool? isBleAdvertising,
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
      isBleAdvertising: isBleAdvertising ?? this.isBleAdvertising,
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
  SosNotifier() : super(const SosState()) {
    _initRelayCallbacks();
    _startBackgroundDiscovery();
  }

  Timer? _activationTimer;
  final GpsService _gpsService = GpsService();
  final SosService _sosService = SosService();
  final WifiDirectSosService _wifiDirectService = WifiDirectSosService();
  final BleSosService _bleService = BleSosService();
  final AudioMorseService _audioMorseService = AudioMorseService();

  void _initRelayCallbacks() {
    _wifiDirectService.onOnlineRelayRequest = (payload) {
      _relaySosOnline(payload);
    };
    _wifiDirectService.onOfflineRelayRequest = (payload) {
      _relaySosOffline(payload);
    };
    _bleService.onOnlineRelayRequest = (payload) {
      _relaySosOnline(payload);
    };
  }

  void _startBackgroundDiscovery() {
    _wifiDirectService.startSosDiscovery();
    _bleService.startScanning(notifier: this);
  }

  void _stopBackgroundDiscovery() {
    _wifiDirectService.stopSosDiscovery();
    _bleService.stopScanning();
  }

  void _relaySosOnline(Map<String, dynamic> relayData) async {
    final apiPayload = {
      'lat': (relayData['lat'] as num?)?.toDouble() ?? 0.0,
      'lng': (relayData['lng'] as num?)?.toDouble() ?? 0.0,
      'message': 'Tourist SOS — relayed by ${relayData['relay_tourist_id'] ?? 'mesh'}',
      'source': 'manual',
      'blockchain_id_hash': relayData['tourist_id'] ?? '',
      'battery_percent': 100,
      'connectivity': 'online',
      'emergency_contacts': [],
      'channel': 'internet',
    };

    await _sosService.relaySos(apiPayload);
  }

  void _relaySosOffline(Map<String, dynamic> payload) async {
    try {
      final String touristId = payload['tourist_id'] ?? '';
      final double lat = (payload['lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (payload['lng'] as num?)?.toDouble() ?? 0.0;
      final int timestamp = (payload['timestamp'] as num?)?.toInt() ?? 0;
      final int hopCount = (payload['hop_count'] as num?)?.toInt() ?? 0;

      if (hopCount > AppConstants.sosHopMax) {
        debugPrint('Offline relay: hop count exceeded max');
        return;
      }

      final blePayload = buildBleSosPayload(
        touristId: touristId,
        lat: lat,
        lng: lng,
        timestamp: timestamp,
        hopCount: hopCount,
      );

      if (mounted) {
        state = state.copyWith(isBleAdvertising: true);
      }
      await _bleService.startAdvertising(payload: blePayload);
    } catch (e) {
      debugPrint('Error during offline relay: $e');
    }
  }

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

  Future<void> activateSos() async {
    await _triggerSos();
  }

  Future<void> _triggerSos() async {
    // Stop background discovery to avoid radio / channel conflicts
    _stopBackgroundDiscovery();

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
      String touristId = '';
      try {
        final blockData = HiveService.blockchainBox.get('current_record');
        if (blockData != null) {
          touristId = (blockData['tourist_id'] ?? blockData['touristId'] ?? '') as String;
        }
      } catch (_) {}

      await Future.wait([
        _fireLayerWifiDirect(touristId, lat, lng),
        _fireLayerBle(touristId, lat, lng),
        _fireLayerAudio(),
      ]);
    }

    // 4. After all attempted layers, transition to acknowledged if at least one channel succeeded
    if (!mounted) return;
    final anySuccess =
        state.layerInternet == SosLayerStatus.success ||
        state.layerSms == SosLayerStatus.success ||
        state.layerWifiDirect == SosLayerStatus.success ||
        state.layerBle == SosLayerStatus.success;
    if (anySuccess && state.status == SosStatus.active) {
      state = state.copyWith(
        status: SosStatus.acknowledged,
        estimatedResponseMin: 8,
      );
    }
  }

  // --- Layer 3: Wi-Fi Direct ---
  Future<void> _fireLayerWifiDirect(String touristId, double lat, double lng) async {
    if (!mounted) return;
    state = state.copyWith(layerWifiDirect: SosLayerStatus.attempting);

    try {
      await _wifiDirectService.startSosAdvertising(
        notifier: this,
        touristId: touristId,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('Error starting Wi-Fi Direct in notifier: $e');
      if (!mounted) return;
      state = state.copyWith(layerWifiDirect: SosLayerStatus.failed);
    }
  }

  // --- Layer 4: BLE ---
  Future<void> _fireLayerBle(String touristId, double lat, double lng) async {
    if (!mounted) return;
    state = state.copyWith(layerBle: SosLayerStatus.attempting, isBleAdvertising: true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final blePayload = buildBleSosPayload(
        touristId: touristId,
        lat: lat,
        lng: lng,
        timestamp: timestamp,
        hopCount: 0,
      );

      await _bleService.startAdvertising(payload: blePayload);
      if (!mounted) return;
      state = state.copyWith(layerBle: SosLayerStatus.success, isBleAdvertising: true);
    } catch (e) {
      debugPrint('Error starting BLE advertisement: $e');
      if (!mounted) return;
      state = state.copyWith(layerBle: SosLayerStatus.failed, isBleAdvertising: false);
    }
  }

  // --- Layer 5: Audio Siren ---
  Future<void> _fireLayerAudio() async {
    if (!mounted) return;
    state = state.copyWith(layerAudio: SosLayerStatus.attempting);

    try {
      await _audioMorseService.startSiren();
      if (!mounted) return;
      state = state.copyWith(layerAudio: SosLayerStatus.success);
    } catch (e) {
      debugPrint('Error starting Audio Morse Siren: $e');
      if (!mounted) return;
      state = state.copyWith(layerAudio: SosLayerStatus.failed);
    }
  }

  // --- Stop all active services ---
  void _stopAllServices() {
    _wifiDirectService.stopSosAdvertising();
    _bleService.stopAdvertising();
    _audioMorseService.stopSiren();
    if (mounted) {
      state = state.copyWith(isBleAdvertising: false);
    }
  }

  // --- Cancel with security code ---
  bool cancelWithCode(String code) {
    // Accept any 4-digit code for now; in production use a user-set PIN
    if (code.length == 4 && RegExp(r'^\d{4}$').hasMatch(code)) {
      _activationTimer?.cancel();
      _activationTimer = null;
      _stopAllServices();
      state = const SosState(status: SosStatus.cancelled);
      // Reset to idle after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = const SosState();
          _startBackgroundDiscovery();
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
    _stopAllServices();
    state = const SosState();
    _startBackgroundDiscovery();
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _stopAllServices();
    _stopBackgroundDiscovery();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final sosStateProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier();
});
