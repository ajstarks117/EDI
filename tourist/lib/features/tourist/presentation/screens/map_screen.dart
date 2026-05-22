import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
                    // Actual Map implementation using Mapbox
                    Positioned.fill(
                      child: _MapboxCanvas(mapState: mapState),
                    ),

                    // Geofencing warnings/alerts overlay
                    if (mapState.triggeredDangerZone != null)
                      Positioned(
                        top: 76,
                        left: 16,
                        right: 16,
                        child: _GeofenceAlertCard(
                          zone: mapState.triggeredDangerZone!,
                          backgroundColor: AppColors.alertRed,
                          icon: Icons.gpp_bad_rounded,
                        ),
                      )
                    else if (mapState.triggeredWeatherZone != null)
                      Positioned(
                        top: 76,
                        left: 16,
                        right: 16,
                        child: _GeofenceAlertCard(
                          zone: mapState.triggeredWeatherZone!,
                          backgroundColor: AppColors.warningAmber,
                          icon: Icons.thunderstorm_rounded,
                        ),
                      )
                    else if (mapState.triggeredSafeZone != null)
                      Positioned(
                        top: 76,
                        left: 16,
                        right: 16,
                        child: _GeofenceAlertCard(
                          zone: mapState.triggeredSafeZone!,
                          backgroundColor: AppColors.safetyTeal,
                          icon: Icons.gpp_good_rounded,
                        ),
                      ),

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

// ---------- Mapbox Canvas ----------

class _MapboxCanvas extends StatefulWidget {
  final MapState mapState;
  const _MapboxCanvas({required this.mapState});

  @override
  State<_MapboxCanvas> createState() => _MapboxCanvasState();
}

class _MapboxCanvasState extends State<_MapboxCanvas> {
  MapboxMap? mapboxMap;
  CircleAnnotationManager? circleAnnotationManager;
  bool _cameraCentered = false;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken("YOUR_MAPBOX_TOKEN");
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    
    // Set default camera centering near Pune Shaniwar Wada
    final initialLng = widget.mapState.currentPosition?.longitude ?? 73.8553;
    final initialLat = widget.mapState.currentPosition?.latitude ?? 18.5195;
    
    mapboxMap.setCamera(CameraOptions(
      center: Point(coordinates: Position(initialLng, initialLat)),
      zoom: widget.mapState.zoomLevel,
    ));

    circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _drawAnnotations();
  }

  @override
  void didUpdateWidget(covariant _MapboxCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapState != widget.mapState) {
      _drawAnnotations();
      
      // Auto-center camera once when GPS coordinates are first resolved
      if (widget.mapState.currentPosition != null && !_cameraCentered && mapboxMap != null) {
        _cameraCentered = true;
        mapboxMap!.setCamera(CameraOptions(
          center: Point(
            coordinates: Position(
              widget.mapState.currentPosition!.longitude,
              widget.mapState.currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
        ));
      }
    }
  }

  Future<void> _drawAnnotations() async {
    final manager = circleAnnotationManager;
    if (manager == null) return;

    await manager.deleteAll();

    // 1. Draw User's Current Location if available
    final userPos = widget.mapState.currentPosition;
    if (userPos != null) {
      // Draw outer pulse indicator
      await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(userPos.longitude, userPos.latitude)),
          circleRadius: 12.0,
          circleColor: const Color(0xFF4285F4).toARGB32(),
          circleOpacity: 0.25,
        ),
      );

      // Draw inner user dot
      await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(userPos.longitude, userPos.latitude)),
          circleRadius: 6.0,
          circleColor: const Color(0xFF4285F4).toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ),
      );
    }

    // 2. Draw Geofence Zones
    for (final zone in widget.mapState.geofenceZones) {
      if (zone.type == GeofenceType.danger && !widget.mapState.showDangerZones) continue;
      if (zone.type == GeofenceType.safe && !widget.mapState.showSafeZones) continue;

      int colorVal = Colors.grey.toARGB32();
      double sizeRadius = 25.0;

      if (zone.type == GeofenceType.danger) {
        colorVal = AppColors.alertRed.toARGB32();
        sizeRadius = 35.0;
      } else if (zone.type == GeofenceType.safe) {
        colorVal = AppColors.safetyTeal.toARGB32();
        sizeRadius = 25.0;
      } else if (zone.type == GeofenceType.weatherAlert) {
        colorVal = AppColors.warningAmber.toARGB32();
        sizeRadius = 45.0;
      }

      // Draw semi-transparent fence boundary
      await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(zone.longitude, zone.latitude)),
          circleRadius: sizeRadius,
          circleColor: colorVal,
          circleOpacity: 0.28,
          circleStrokeColor: colorVal,
          circleStrokeWidth: 1.5,
        ),
      );

      // Draw solid center focal point
      await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(zone.longitude, zone.latitude)),
          circleRadius: 4.5,
          circleColor: colorVal,
          circleOpacity: 0.95,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      onMapCreated: _onMapCreated,
      styleUri: MapboxStyles.MAPBOX_STREETS,
    );
  }
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

class _MapLegend extends StatefulWidget {
  final MapState mapState;
  const _MapLegend({required this.mapState});

  @override
  State<_MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<_MapLegend> {
  bool _isExpanded = true;

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
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Map Legend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, size: 16),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 6),
            const _LegendItem(color: Color(0xFF4285F4), label: 'Your location'),
            if (widget.mapState.showDangerZones)
              const _LegendItem(color: AppColors.alertRed, label: 'Danger zone'),
            if (widget.mapState.showSafeZones)
              const _LegendItem(color: AppColors.safetyTeal, label: 'Safe zone'),
            if (widget.mapState.showNetworkStrength)
              const _LegendItem(color: AppColors.successGreen, label: 'Network coverage'),
            const _LegendItem(color: AppColors.warningAmber, label: 'Weather alert'),
          ]
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

// ---------- Geofence Warning/Alert Card ----------

class _GeofenceAlertCard extends StatefulWidget {
  final GeofenceZone zone;
  final Color backgroundColor;
  final IconData icon;

  const _GeofenceAlertCard({
    required this.zone,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  State<_GeofenceAlertCard> createState() => _GeofenceAlertCardState();
}

class _GeofenceAlertCardState extends State<_GeofenceAlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = widget.zone.type == GeofenceType.danger;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: _glowAnimation.value),
                blurRadius: 12,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isDanger ? 'DANGER ZONE ENCOUNTERED' : 'AREA NOTICE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.zone.label,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDanger) ...[
              ElevatedButton(
                onPressed: () => context.push('/sos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.alertRed,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                child: const Text('SOS'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
