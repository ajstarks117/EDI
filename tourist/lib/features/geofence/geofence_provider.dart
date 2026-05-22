import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../safety/services/gps_service.dart';
import 'geofence_cache_service.dart';
import 'geofence_checker.dart';
import 'geofence_notification_service.dart';
import 'geofence_zone.dart';

class GeofenceState {
  final List<GeofenceZone> allZones;
  final List<GeofenceZone> activeZones;
  final Set<String> acknowledgedZoneIds;
  final bool isLoading;

  const GeofenceState({
    this.allZones = const [],
    this.activeZones = const [],
    this.acknowledgedZoneIds = const {},
    this.isLoading = false,
  });

  GeofenceState copyWith({
    List<GeofenceZone>? allZones,
    List<GeofenceZone>? activeZones,
    Set<String>? acknowledgedZoneIds,
    bool? isLoading,
  }) {
    return GeofenceState(
      allZones: allZones ?? this.allZones,
      activeZones: activeZones ?? this.activeZones,
      acknowledgedZoneIds: acknowledgedZoneIds ?? this.acknowledgedZoneIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GeofenceNotifier extends StateNotifier<GeofenceState> {
  final Ref _ref;
  final GeofenceCacheService _cacheService;

  GeofenceNotifier(this._ref, {GeofenceCacheService? cacheService})
      : _cacheService = cacheService ?? GeofenceCacheService(),
        super(const GeofenceState()) {
    _init();
  }

  void _init() {
    // 1. Load initial cached zones from Hive box
    _cacheService.getCachedZones().then((cached) {
      state = state.copyWith(allZones: cached);
      
      // If we already have a position in the provider, perform initial evaluation
      final currentLoc = _ref.read(locationStreamProvider).value;
      if (currentLoc != null) {
        _onLocationUpdate(currentLoc);
      }
    });

    // 2. Set up listener on Rishi's location stream
    _ref.listen<AsyncValue<Position>>(locationStreamProvider, (prev, next) {
      next.when(
        data: (position) {
          _onLocationUpdate(position);
        },
        error: (err, stack) {
          debugPrint('Geofence location stream error: $err');
        },
        loading: () {},
      );
    }, fireImmediately: true);
  }

  /// Synchronize zones with the server and evaluate the current position
  Future<void> syncAndRefresh() async {
    state = state.copyWith(isLoading: true);
    final freshZones = await _cacheService.fetchAndCacheZones();
    state = state.copyWith(allZones: freshZones, isLoading: false);

    // Re-check current position if available
    final currentLoc = _ref.read(locationStreamProvider).value;
    if (currentLoc != null) {
      _onLocationUpdate(currentLoc);
    }
  }

  void _onLocationUpdate(Position position) {
    final LatLng latLng = LatLng(position.latitude, position.longitude);
    final containingZones = GeofenceChecker.checkPosition(latLng, state.allZones);

    final previousActiveIds = state.activeZones.map((z) => z.id).toSet();
    final currentActiveIds = containingZones.map((z) => z.id).toSet();

    // Check if the set of active zones differs from the previous check
    final bool hasChanged = previousActiveIds.length != currentActiveIds.length ||
        !previousActiveIds.containsAll(currentActiveIds);

    if (hasChanged) {
      // Find zones that have just been entered
      final newlyEntered = containingZones.where((z) => !previousActiveIds.contains(z.id)).toList();

      final newAcknowledged = Set<String>.from(state.acknowledgedZoneIds);

      for (final zone in newlyEntered) {
        // Reset acknowledged status when entering/re-entering a zone
        newAcknowledged.remove(zone.id);

        // Send local notification if the app is in the background
        final isBackground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
        if (isBackground) {
          GeofenceNotificationService.showBackgroundAlert(zone);
        }
      }

      state = state.copyWith(
        activeZones: containingZones,
        acknowledgedZoneIds: newAcknowledged,
      );

      // Adapt GPS update interval frequency
      _adaptGpsInterval(containingZones);
    }
  }

  void _adaptGpsInterval(List<GeofenceZone> active) {
    // High-risk interval (10 seconds) if inside warning, restricted or exclusion zones.
    // Normal interval (30 seconds) if outside all zones.
    final bool insideRiskZone = active.isNotEmpty;
    final int targetInterval = insideRiskZone ? AppConstants.gpsIntervalHighRisk : AppConstants.gpsIntervalNormal;

    // Update Rishi's GPS interval state provider
    final notifier = _ref.read(gpsIntervalProvider.notifier);
    if (notifier.state != targetInterval) {
      notifier.state = targetInterval;
      debugPrint('Adapted GPS Scan Interval to: $targetInterval seconds');
    }
  }

  /// Mark a zone as acknowledged to dismiss its overlay
  void acknowledgeZone(String zoneId) {
    final newAck = Set<String>.from(state.acknowledgedZoneIds)..add(zoneId);
    state = state.copyWith(acknowledgedZoneIds: newAck);
  }
}

// ---------------------------------------------------------------------------
// Provider definition
// ---------------------------------------------------------------------------

final geofenceProvider = StateNotifierProvider<GeofenceNotifier, GeofenceState>((ref) {
  return GeofenceNotifier(ref);
});
