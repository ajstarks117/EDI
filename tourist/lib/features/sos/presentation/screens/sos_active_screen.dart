import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../../core/constants/ui_constants.dart';
import '../providers/sos_state.dart';

class SosActiveScreen extends ConsumerStatefulWidget {
  const SosActiveScreen({super.key});

  @override
  ConsumerState<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends ConsumerState<SosActiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _headerFlashController;
  late final Animation<double> _headerFlash;
  double? _previousBrightness;

  @override
  void initState() {
    super.initState();

    // Pulsing SOS circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Header flash (opacity pulse)
    _headerFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _headerFlash = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _headerFlashController, curve: Curves.easeInOut),
    );

    _setMaxBrightness();
  }

  Future<void> _setMaxBrightness() async {
    try {
      _previousBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {
      // screen_brightness not available on this platform — graceful fallback
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_previousBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_previousBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _headerFlashController.dispose();
    _restoreBrightness();
    super.dispose();
  }

  void _showCancelDialog() {
    final codeController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A0A0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiConstants.radiusLG),
                side: BorderSide(color: AppColors.alertRed.withValues(alpha: 0.4)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.alertRed, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel SOS',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your 4-digit security code to cancel the active SOS alert.',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • •',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 28,
                        letterSpacing: 12,
                      ),
                      errorText: errorText,
                      errorStyle: const TextStyle(color: AppColors.alertRed),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        borderSide: const BorderSide(color: AppColors.alertRed),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        borderSide: const BorderSide(color: AppColors.alertRed),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                        borderSide: const BorderSide(color: AppColors.alertRed, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final code = codeController.text;
                    final success = ref.read(sosStateProvider.notifier).cancelWithCode(code);
                    if (success) {
                      Navigator.of(ctx).pop();
                      _restoreBrightness();
                      if (context.mounted) {
                        context.go('/home');
                      }
                    } else {
                      setDialogState(() {
                        errorText = 'Invalid code. Enter 4 digits.';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiConstants.radiusSM),
                    ),
                  ),
                  child: Text('Confirm Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosStateProvider);

    // If SOS was cancelled or resolved, go home
    ref.listen<SosState>(sosStateProvider, (prev, next) {
      if (next.status == SosStatus.cancelled || next.status == SosStatus.resolved) {
        _restoreBrightness();
        if (context.mounted) context.go('/home');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0404),
        body: SafeArea(
          child: Column(
            children: [
              // ─── Red header bar ───
              _buildHeader(sosState),

              const SizedBox(height: 12),

              // ─── Pulsing SOS circle ───
              Expanded(
                flex: 3,
                child: Center(
                  child: _buildSosCircle(sosState),
                ),
              ),

              // ─── Status message ───
              _buildStatusMessage(sosState),
              const SizedBox(height: 16),

              // ─── 5 Layer rows ───
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _LayerRow(
                        icon: Icons.wifi_rounded,
                        label: 'Internet',
                        status: sosState.layerInternet,
                      ),
                      _LayerRow(
                        icon: Icons.sms_rounded,
                        label: 'SMS',
                        status: sosState.layerSms,
                      ),
                      _LayerRow(
                        icon: Icons.wifi_tethering_rounded,
                        label: 'Wi-Fi Direct',
                        status: sosState.layerWifiDirect,
                      ),
                      _LayerRow(
                        icon: Icons.bluetooth_rounded,
                        label: 'BLE',
                        status: sosState.layerBle,
                      ),
                      _LayerRow(
                        icon: Icons.volume_up_rounded,
                        label: 'Audio Siren',
                        status: sosState.layerAudio,
                      ),
                    ],
                  ),
                ),
              ),

              // ─── GPS & SOS ID ───
              _buildFooterInfo(sosState),

              // ─── Cancel button ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _showCancelDialog,
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: Text(
                      'Cancel SOS (Security Code)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(SosState sosState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.alertRed.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pulsing SOS ACTIVE badge
          AnimatedBuilder(
            animation: _headerFlash,
            builder: (context, child) {
              return Opacity(
                opacity: _headerFlash.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.alertRed,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alertRed.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    'SOS ACTIVE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SOS ID
          if (sosState.sosId != null)
            Text(
              sosState.sosId!.length > 12
                  ? '${sosState.sosId!.substring(0, 12)}…'
                  : sosState.sosId!,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  // ─── SOS Circle ───
  Widget _buildSosCircle(SosState sosState) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.alertRed, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.alertRed.withValues(alpha: 0.35),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'SOS',
            style: GoogleFonts.inter(
              color: AppColors.alertRed,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status message ───
  Widget _buildStatusMessage(SosState sosState) {
    String message;
    Color color;

    switch (sosState.status) {
      case SosStatus.active:
        message = 'Help is being contacted…';
        color = Colors.white70;
        break;
      case SosStatus.acknowledged:
        message = 'Help confirmed — on the way';
        color = AppColors.successGreen;
        break;
      case SosStatus.responding:
        final eta = sosState.estimatedResponseMin ?? 0;
        message = 'Responder en-route — ETA ${eta}min';
        color = AppColors.successGreen;
        break;
      default:
        message = 'EMERGENCY SOS';
        color = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (sosState.estimatedResponseMin != null &&
              sosState.status == SosStatus.acknowledged)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Est. response: ${sosState.estimatedResponseMin} min',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Footer info ───
  Widget _buildFooterInfo(SosState sosState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_rounded,
              color: AppColors.alertRed.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Coordinates',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  sosState.locationText ?? 'Acquiring…',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (sosState.relayedBy != null)
            Chip(
              label: Text(
                'Relayed',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: AppColors.warningAmber.withValues(alpha: 0.3),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layer row widget
// ---------------------------------------------------------------------------

class _LayerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final SosLayerStatus status;

  const _LayerRow({
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;
    final Widget trailing;

    switch (status) {
      case SosLayerStatus.idle:
        bgColor = Colors.white.withValues(alpha: 0.03);
        borderColor = Colors.white.withValues(alpha: 0.06);
        iconColor = Colors.white24;
        textColor = Colors.white38;
        trailing = Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.15), size: 20);
        break;
      case SosLayerStatus.attempting:
        bgColor = AppColors.warningAmber.withValues(alpha: 0.08);
        borderColor = AppColors.warningAmber.withValues(alpha: 0.25);
        iconColor = AppColors.warningAmber;
        textColor = Colors.white;
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.warningAmber,
          ),
        );
        break;
      case SosLayerStatus.success:
        bgColor = AppColors.successGreen.withValues(alpha: 0.1);
        borderColor = AppColors.successGreen.withValues(alpha: 0.3);
        iconColor = AppColors.successGreen;
        textColor = Colors.white;
        trailing = const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20);
        break;
      case SosLayerStatus.failed:
        bgColor = AppColors.alertRed.withValues(alpha: 0.08);
        borderColor = AppColors.alertRed.withValues(alpha: 0.25);
        iconColor = AppColors.alertRed;
        textColor = Colors.white70;
        trailing = const Icon(Icons.cancel_rounded, color: AppColors.alertRed, size: 20);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(UiConstants.radiusMD),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: status == SosLayerStatus.success
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
