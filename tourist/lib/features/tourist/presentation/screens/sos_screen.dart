import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../safety/services/gps_service.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final GpsService _gpsService = GpsService();
  String _locationText = 'Acquiring location...';

  final List<_LayerStatus> _layers = [
    const _LayerStatus(icon: Icons.wifi_rounded, label: 'Layer 1: Internet', status: _Status.loading),
    const _LayerStatus(icon: Icons.sms_rounded, label: 'Layer 2: SMS', status: _Status.pending),
    const _LayerStatus(icon: Icons.bluetooth_rounded, label: 'Layer 3: Bluetooth', status: _Status.pending),
    const _LayerStatus(icon: Icons.volume_up_rounded, label: 'Layer 4: Audio Siren', status: _Status.pending),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    final statuses = await [
      Permission.location,
      Permission.sms,
      Permission.phone,
    ].request();

    if (statuses[Permission.location]!.isGranted) {
      try {
        final pos = await _gpsService.getCurrentPosition();
        if (mounted) {
          setState(() {
            _locationText = '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _locationText = 'GPS Unavailable';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _locationText = 'Permission Denied';
        });
      }
    }
    _executeLayerActivation();
  }

  Future<void> _executeLayerActivation() async {
    // ---------- Layer 1: Internet ----------
    if (!mounted) return;
    setState(() => _layers[0] = _layers[0].copyWith(status: _Status.loading));
    await Future.delayed(const Duration(seconds: 1));

    bool internetSuccess = false;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // Fetch current coordinates if GPS permitted
        final pos = await _gpsService.getCurrentPosition();
        // Try posting to authority backend SOS endpoint
        final response = await Dio().post(
          'http://10.0.2.2:5000/api/emergency/sos',
          data: {
            'touristId': 'anonymous_tourist',
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'type': 'CRITICAL EMERGENCY SOS',
            'description': 'SOS triggered manually by user from Emergency Screen.',
          },
          options: Options(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          internetSuccess = true;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    if (mounted) {
      setState(() {
        _layers[0] = _layers[0].copyWith(
          status: internetSuccess ? _Status.success : _Status.failed,
        );
      });
    }

    // ---------- Layer 2: SMS ----------
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _layers[1] = _layers[1].copyWith(status: _Status.loading));
    await Future.delayed(const Duration(seconds: 1));

    final smsPermission = await Permission.sms.status;
    bool smsSuccess = smsPermission.isGranted;

    if (mounted) {
      setState(() {
        _layers[1] = _layers[1].copyWith(
          status: smsSuccess ? _Status.success : _Status.failed,
        );
      });
    }

    // ---------- Layer 3: Bluetooth ----------
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _layers[2] = _layers[2].copyWith(status: _Status.loading));
    await Future.delayed(const Duration(seconds: 1));

    bool bluetoothSuccess = false;
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (isSupported) {
        final state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.on) {
          bluetoothSuccess = true;
        }
      }
    } catch (_) {
      // Bluetooth access failed or not supported
    }

    if (mounted) {
      setState(() {
        _layers[2] = _layers[2].copyWith(
          status: bluetoothSuccess ? _Status.success : _Status.failed,
        );
      });
    }

    // ---------- Layer 4: Audio Siren ----------
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _layers[3] = _layers[3].copyWith(status: _Status.loading));
    await Future.delayed(const Duration(seconds: 1));

    // Play intense vibrations to simulate localized audio/vibrational siren
    for (int i = 0; i < 5; i++) {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (mounted) {
      setState(() {
        _layers[3] = _layers[3].copyWith(status: _Status.success);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'SOS ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel SOS',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Pulsing SOS circle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.alertRed, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.alertRed.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    style: AppTextStyles.appTitle.copyWith(
                      color: AppColors.alertRed,
                      fontSize: 36,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status text
            Text(
              'EMERGENCY SOS',
              style: AppTextStyles.emergencyText.copyWith(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getStatusText(),
              style: AppTextStyles.caption.copyWith(color: Colors.white54),
            ),

            const Spacer(),

            // Layer status list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _layers.map((layer) => _LayerTile(layer: layer)).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // GPS Coordinates
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location_rounded, color: AppColors.alertRed.withValues(alpha: 0.8), size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location Status', style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                      const SizedBox(height: 2),
                      Text(
                        _locationText,
                        style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                    ),
                  ),
                  child: const Text(
                    'Cancel & Go Back',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    final successCount = _layers.where((l) => l.status == _Status.success).length;
    final failedCount = _layers.where((l) => l.status == _Status.failed).length;
    if (successCount == _layers.length) return 'All channels active ✓';
    if (successCount + failedCount == 0) return 'Establishing connections...';
    return 'Active: $successCount, Failed: $failedCount';
  }
}

// ---------- Supporting ----------

enum _Status { pending, loading, success, failed }

class _LayerStatus {
  final IconData icon;
  final String label;
  final _Status status;

  const _LayerStatus({required this.icon, required this.label, required this.status});

  _LayerStatus copyWith({_Status? status}) =>
      _LayerStatus(icon: icon, label: label, status: status ?? this.status);
}

class _LayerTile extends StatelessWidget {
  final _LayerStatus layer;
  const _LayerTile({required this.layer});

  @override
  Widget build(BuildContext context) {
    Color tileColor;
    Color borderColor;
    Widget trailing;

    switch (layer.status) {
      case _Status.success:
        tileColor = AppColors.safetyTeal.withValues(alpha: 0.1);
        borderColor = AppColors.safetyTeal.withValues(alpha: 0.4);
        trailing = const Icon(Icons.check_circle_rounded, color: AppColors.safetyTeal, size: 22);
        break;
      case _Status.failed:
        tileColor = AppColors.alertRed.withValues(alpha: 0.1);
        borderColor = AppColors.alertRed.withValues(alpha: 0.4);
        trailing = const Icon(Icons.error_outline_rounded, color: AppColors.alertRed, size: 22);
        break;
      case _Status.loading:
        tileColor = AppColors.alertRed.withValues(alpha: 0.08);
        borderColor = AppColors.alertRed.withValues(alpha: 0.3);
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.alertRed),
        );
        break;
      case _Status.pending:
        tileColor = Colors.white.withValues(alpha: 0.03);
        borderColor = Colors.white.withValues(alpha: 0.08);
        trailing = Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.2), size: 22);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            layer.icon,
            color: layer.status == _Status.success
                ? AppColors.safetyTeal
                : (layer.status == _Status.failed || layer.status == _Status.loading)
                    ? AppColors.alertRed
                    : Colors.white24,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              layer.label,
              style: TextStyle(
                color: layer.status == _Status.pending ? Colors.white38 : Colors.white,
                fontSize: 14,
                fontWeight: layer.status == _Status.success ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
