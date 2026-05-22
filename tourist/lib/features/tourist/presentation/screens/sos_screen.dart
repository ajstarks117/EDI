import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/ui_constants.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

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

    _simulateLayerActivation();
  }

  Future<void> _simulateLayerActivation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _layers[0] = _layers[0].copyWith(status: _Status.success));

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _layers[1] = _layers[1].copyWith(status: _Status.loading));

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _layers[1] = _layers[1].copyWith(status: _Status.success));

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _layers[2] = _layers[2].copyWith(status: _Status.loading));

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _layers[2] = _layers[2].copyWith(status: _Status.success));

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _layers[3] = _layers[3].copyWith(status: _Status.loading));

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _layers[3] = _layers[3].copyWith(status: _Status.success));
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
                      Text(
                        'GPS Coordinates',
                        style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '18.614646, 73.848604',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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
    if (successCount == _layers.length) return 'All channels active ✓';
    if (successCount == 0) return 'Establishing connections...';
    return 'Alert sent via $successCount channel${successCount > 1 ? 's' : ''} ✓';
  }
}

// ---------- Supporting ----------

enum _Status { pending, loading, success }

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
                : layer.status == _Status.loading
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
