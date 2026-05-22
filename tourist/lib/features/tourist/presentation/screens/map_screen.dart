import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/ui_constants.dart';
import '../providers/map_provider.dart';
import '../providers/settings_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Safety Map',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showLayerSheet(context, ref),
            icon: const Icon(Icons.layers_rounded, color: Colors.white),
          ),
        ],
      ),
      body: mapState.gpsStatus == GpsStatus.denied
          ? _GpsDeniedView(onRetry: () => ref.read(mapProvider.notifier).setGpsGranted())
          : mapState.gpsStatus == GpsStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // Map canvas (mock interactive)
                    _MockMapCanvas(mapState: mapState),

                    // Zoom controls
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Column(
                        children: [
                          _MapControlButton(
                            icon: Icons.add,
                            onTap: () => ref.read(mapProvider.notifier).zoomIn(),
                          ),
                          const SizedBox(height: 8),
                          _MapControlButton(
                            icon: Icons.remove,
                            onTap: () => ref.read(mapProvider.notifier).zoomOut(),
                          ),
                        ],
                      ),
                    ),

                    // Map legend
                    Positioned(
                      left: 16,
                      top: 16,
                      child: _MapLegend(mapState: mapState),
                    ),

                    // Bottom safety controls
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _SafetyControlPanel(ref: ref),
                    ),
                  ],
                ),
    );
  }

  void _showLayerSheet(BuildContext context, WidgetRef ref) {
    final mapState = ref.read(mapProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UiConstants.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map Layers',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Danger Zones', style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    subtitle: Text('Show geo-fenced danger areas', style: GoogleFonts.inter(fontSize: 11.5)),
                    value: mapState.showDangerZones,
                    activeThumbColor: AppColors.alertRed,
                    activeTrackColor: AppColors.alertRed.withValues(alpha: 0.25),
                    onChanged: (val) {
                      ref.read(mapProvider.notifier).toggleDangerZones(val);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text('Safe Zones', style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    subtitle: Text('Show known safe areas', style: GoogleFonts.inter(fontSize: 11.5)),
                    value: mapState.showSafeZones,
                    activeThumbColor: AppColors.safetyTeal,
                    activeTrackColor: AppColors.safetyTeal.withValues(alpha: 0.25),
                    onChanged: (val) {
                      ref.read(mapProvider.notifier).toggleSafeZones(val);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text('Network Strength', style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    subtitle: Text('Cell tower signal overlay', style: GoogleFonts.inter(fontSize: 11.5)),
                    value: mapState.showNetworkStrength,
                    activeThumbColor: AppColors.successGreen,
                    activeTrackColor: AppColors.successGreen.withValues(alpha: 0.25),
                    onChanged: (val) {
                      ref.read(mapProvider.notifier).toggleNetworkStrength(val);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text('Other Tourists', style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    subtitle: Text('Show nearby tourists (if opted-in)', style: GoogleFonts.inter(fontSize: 11.5)),
                    value: mapState.showOtherTourists,
                    activeThumbColor: AppColors.primaryNavy,
                    activeTrackColor: AppColors.primaryNavy.withValues(alpha: 0.25),
                    onChanged: (val) {
                      ref.read(mapProvider.notifier).toggleOtherTourists(val);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- Mock Map Canvas ----------

class _MockMapCanvas extends StatelessWidget {
  final MapState mapState;
  const _MockMapCanvas({required this.mapState});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0F8),
      child: CustomPaint(
        painter: _MapPainter(mapState: mapState),
        size: Size.infinite,
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final MapState mapState;
  _MapPainter({required this.mapState});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = mapState.zoomLevel / 14.0;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFD0DDE8)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40 * scale) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40 * scale) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 8 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), roadPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), roadPaint);
    canvas.drawLine(Offset(centerX - 150, 0), Offset(centerX + 150, size.height), roadPaint);

    // Danger zones
    if (mapState.showDangerZones) {
      final dangerPaint = Paint()
        ..color = AppColors.alertRed.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final dangerBorderPaint = Paint()
        ..color = AppColors.alertRed.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(centerX + 100, centerY - 80), 55 * scale, dangerPaint);
      canvas.drawCircle(Offset(centerX + 100, centerY - 80), 55 * scale, dangerBorderPaint);

      canvas.drawCircle(Offset(centerX - 120, centerY + 130), 40 * scale, dangerPaint);
      canvas.drawCircle(Offset(centerX - 120, centerY + 130), 40 * scale, dangerBorderPaint);
    }

    // Safe zones
    if (mapState.showSafeZones) {
      final safePaint = Paint()
        ..color = AppColors.safetyTeal.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final safeBorderPaint = Paint()
        ..color = AppColors.safetyTeal.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(centerX - 80, centerY - 60), 65 * scale, safePaint);
      canvas.drawCircle(Offset(centerX - 80, centerY - 60), 65 * scale, safeBorderPaint);

      canvas.drawCircle(Offset(centerX + 60, centerY + 100), 50 * scale, safePaint);
      canvas.drawCircle(Offset(centerX + 60, centerY + 100), 50 * scale, safeBorderPaint);
    }

    // Network strength
    if (mapState.showNetworkStrength) {
      final towerPaint = Paint()
        ..color = AppColors.successGreen.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      final towerBorder = Paint()
        ..color = AppColors.successGreen.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(Offset(centerX, centerY - 120), 80 * scale, towerPaint);
      canvas.drawCircle(Offset(centerX, centerY - 120), 80 * scale, towerBorder);
      canvas.drawCircle(Offset(centerX + 130, centerY + 50), 70 * scale, towerPaint);
      canvas.drawCircle(Offset(centerX + 130, centerY + 50), 70 * scale, towerBorder);
    }

    // User location beacon
    final userOuterPaint = Paint()
      ..color = const Color(0xFF4285F4).withValues(alpha: 0.15);
    final userInnerPaint = Paint()..color = const Color(0xFF4285F4);
    final userBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(centerX, centerY), 30 * scale, userOuterPaint);
    canvas.drawCircle(Offset(centerX, centerY), 8, userInnerPaint);
    canvas.drawCircle(Offset(centerX, centerY), 8, userBorder);

    // Other tourists
    if (mapState.showOtherTourists) {
      final rng = Random(42);
      final touristPaint = Paint()..color = AppColors.primaryNavy;
      for (int i = 0; i < 5; i++) {
        final tx = centerX + (rng.nextDouble() - 0.5) * 250;
        final ty = centerY + (rng.nextDouble() - 0.5) * 300;
        canvas.drawCircle(Offset(tx, ty), 5, touristPaint);
        final outerPaint = Paint()
          ..color = AppColors.primaryNavy.withValues(alpha: 0.15);
        canvas.drawCircle(Offset(tx, ty), 12, outerPaint);
      }
    }

    // Weather alert marker
    _drawWeatherMarker(canvas, Offset(centerX + 140, centerY - 140), scale);
  }

  void _drawWeatherMarker(Canvas canvas, Offset pos, double scale) {
    final bgPaint = Paint()..color = AppColors.warningAmber.withValues(alpha: 0.2);
    final borderPaint = Paint()
      ..color = AppColors.warningAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(pos, 18 * scale, bgPaint);
    canvas.drawCircle(pos, 18 * scale, borderPaint);

    // ⚡ lightning bolt (simplified triangle)
    final bolt = Paint()..color = AppColors.warningAmber;
    final path = Path()
      ..moveTo(pos.dx - 4, pos.dy - 8)
      ..lineTo(pos.dx + 2, pos.dy - 1)
      ..lineTo(pos.dx - 1, pos.dy - 1)
      ..lineTo(pos.dx + 4, pos.dy + 8)
      ..lineTo(pos.dx - 2, pos.dy + 1)
      ..lineTo(pos.dx + 1, pos.dy + 1)
      ..close();
    canvas.drawPath(path, bolt);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.mapState != mapState;
}

// ---------- Supporting Widgets ----------

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryNavy, size: 22),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final MapState mapState;
  const _MapLegend({required this.mapState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(UiConstants.radiusSM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Map Legend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const _LegendItem(color: Color(0xFF4285F4), label: 'Your location'),
          if (mapState.showDangerZones)
            const _LegendItem(color: AppColors.alertRed, label: 'Danger zone'),
          if (mapState.showSafeZones)
            const _LegendItem(color: AppColors.safetyTeal, label: 'Safe zone'),
          if (mapState.showNetworkStrength)
            const _LegendItem(color: AppColors.successGreen, label: 'Network coverage'),
          const _LegendItem(color: AppColors.warningAmber, label: 'Weather alert'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _SafetyControlPanel extends StatefulWidget {
  final WidgetRef ref;
  const _SafetyControlPanel({required this.ref});

  @override
  State<_SafetyControlPanel> createState() => _SafetyControlPanelState();
}

class _SafetyControlPanelState extends State<_SafetyControlPanel> {
  double _sliderValue = 0.0;
  bool _showSafetyOptions = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          GestureDetector(
            onTap: () => setState(() => _showSafetyOptions = !_showSafetyOptions),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.safetyTeal, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Safety Features',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      ),
                      Icon(
                        _showSafetyOptions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_showSafetyOptions) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    dense: true,
                    title: const Text('Crash / Fall Detection', style: TextStyle(fontSize: 13)),
                    value: settings.crashDetectionEnabled,
                    activeThumbColor: AppColors.safetyTeal,
                    onChanged: (val) => widget.ref.read(settingsProvider.notifier).toggleCrashDetection(val),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Backtracking', style: TextStyle(fontSize: 13)),
                    value: settings.backtrackingEnabled,
                    activeThumbColor: AppColors.safetyTeal,
                    onChanged: (val) => widget.ref.read(settingsProvider.notifier).toggleBacktracking(val),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Share Location with Group', style: TextStyle(fontSize: 13)),
                    value: settings.shareLocationWithOthers,
                    activeThumbColor: AppColors.safetyTeal,
                    onChanged: (val) => widget.ref.read(settingsProvider.notifier).toggleShareLocation(val),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Scanner — Add party member (coming soon)'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Scan QR to Add Party Member'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.safetyTeal,
                      side: const BorderSide(color: AppColors.safetyTeal),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Emergency Slider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.alertRed.withValues(alpha: 0.08 + _sliderValue * 0.4),
                    AppColors.alertRed.withValues(alpha: 0.15 + _sliderValue * 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.alertRed.withValues(alpha: 0.3 + _sliderValue * 0.7),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _sliderValue > 0.85
                        ? '🚨 ACTIVATING...'
                        : '⟫ ⟫ ⟫  Slide to Broadcast Emergency  ⟫ ⟫ ⟫',
                    style: TextStyle(
                      color: AppColors.alertRed,
                      fontSize: 12,
                      fontWeight: _sliderValue > 0.85 ? FontWeight.bold : FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 56,
                      activeTrackColor: AppColors.alertRed.withValues(alpha: 0.2),
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: AppColors.alertRed,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 22),
                      overlayShape: SliderComponentShape.noOverlay,
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: (val) => setState(() => _sliderValue = val),
                      onChangeEnd: (val) {
                        if (val > 0.85) {
                          context.push('/sos');
                        }
                        setState(() => _sliderValue = 0.0);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _GpsDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 80, color: AppColors.mutedText.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('GPS Access Required', style: AppTextStyles.screenTitle),
            const SizedBox(height: 8),
            Text(
              'Please enable location services to view the safety map and receive real-time alerts.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.location_on_rounded),
              label: const Text('Enable GPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
