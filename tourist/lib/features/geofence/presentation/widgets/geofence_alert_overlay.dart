import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../geofence_provider.dart';
import '../../../../core/constants/ui_constants.dart';

class GeofenceAlertOverlay extends ConsumerWidget {
  const GeofenceAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofenceState = ref.watch(geofenceProvider);
    final activeZones = geofenceState.activeZones;
    final acknowledged = geofenceState.acknowledgedZoneIds;

    // Find the first active zone that hasn't been acknowledged yet
    final unacknowledged = activeZones.where((z) => !acknowledged.contains(z.id)).toList();
    if (unacknowledged.isEmpty) {
      return const SizedBox.shrink();
    }

    final zone = unacknowledged.first;

    // Visual attributes based on zone type
    Color accentColor;
    String alertTitle;
    String alertDescription;
    IconData alertIcon;

    switch (zone.zoneType.toLowerCase()) {
      case 'warning':
        accentColor = AppColors.warningAmber;
        alertTitle = 'CAUTION — ${zone.name}';
        alertDescription = zone.advisoryText.isNotEmpty 
            ? zone.advisoryText 
            : 'You are entering a Warning Zone. Please stay cautious.';
        alertIcon = Icons.warning_amber_rounded;
        break;
      case 'restricted':
        accentColor = const Color(0xFFE65100); // Deep Orange
        alertTitle = 'WARNING — Exit this area';
        alertDescription = zone.advisoryText.isNotEmpty
            ? '${zone.name}: ${zone.advisoryText}'
            : 'You are inside a Restricted Zone. Turn back immediately.';
        alertIcon = Icons.report_problem_rounded;
        break;
      case 'exclusion':
        accentColor = AppColors.alertRed;
        alertTitle = 'DANGER — Immediate risk. Consider SOS.';
        alertDescription = zone.advisoryText.isNotEmpty
            ? '${zone.name}: ${zone.advisoryText}'
            : 'You have entered an Exclusion Zone. High risk detected.';
        alertIcon = Icons.dangerous_rounded;
        break;
      default:
        accentColor = AppColors.primaryNavy;
        alertTitle = zone.name;
        alertDescription = zone.advisoryText;
        alertIcon = Icons.info_outline;
    }

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Glassmorphic background blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Centered Emergency Alert Box
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Slate 800 dark theme background
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Alert Header banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22.0),
                            topRight: Radius.circular(22.0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                alertIcon,
                                color: accentColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              alertTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Text Description & Actions
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              alertDescription,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  ref.read(geofenceProvider.notifier).acknowledgeZone(zone.id);
                                },
                                child: Text(
                                  'Acknowledge & Close',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            // SOS trigger fallback option (exclusion zones only)
                            if (zone.zoneType.toLowerCase() == 'exclusion') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.alertRed,
                                    side: const BorderSide(color: AppColors.alertRed, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    ref.read(geofenceProvider.notifier).acknowledgeZone(zone.id);
                                    context.push('/sos');
                                  },
                                  icon: const Icon(Icons.sos_outlined, size: 22),
                                  label: Text(
                                    'TRIGGER SOS PANIC',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
