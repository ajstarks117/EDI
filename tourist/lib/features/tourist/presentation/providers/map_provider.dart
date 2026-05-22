import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../safety/services/gps_service.dart';

enum GpsStatus { granted, denied, loading }
enum InternetStatus { online, offline }

/// A geofence zone (danger, safe, weather alert) to be rendered on the map.
class GeofenceZone {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceType type;

  const GeofenceZone({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.type,
  });
}

enum GeofenceType { danger, safe, weatherAlert }

class MapState {
  final bool showDangerZones;
  final bool showSafeZones;
  final bool showNetworkStrength;
  final bool showOtherTourists;
  final GpsStatus gpsStatus;
  final InternetStatus internetStatus;
  final double zoomLevel;
  final Position? currentPosition;
  final List<GeofenceZone> geofenceZones;
  final GeofenceZone? triggeredDangerZone;
  final GeofenceZone? triggeredSafeZone;
  final GeofenceZone? triggeredWeatherZone;

  const MapState({
    this.showDangerZones = true,
    this.showSafeZones = true,
    this.showNetworkStrength = false,
    this.showOtherTourists = false,
    this.gpsStatus = GpsStatus.loading,
    this.internetStatus = InternetStatus.online,
    this.zoomLevel = 14.0,
    this.currentPosition,
    this.geofenceZones = const [],
    this.triggeredDangerZone,
    this.triggeredSafeZone,
    this.triggeredWeatherZone,
  });

  MapState copyWith({
    bool? showDangerZones,
    bool? showSafeZones,
    bool? showNetworkStrength,
    bool? showOtherTourists,
    GpsStatus? gpsStatus,
    InternetStatus? internetStatus,
    double? zoomLevel,
    Position? currentPosition,
    List<GeofenceZone>? geofenceZones,
    GeofenceZone? triggeredDangerZone,
    GeofenceZone? triggeredSafeZone,
    GeofenceZone? triggeredWeatherZone,
    bool clearDanger = false,
    bool clearSafe = false,
    bool clearWeather = false,
  }) {
    return MapState(
      showDangerZones: showDangerZones ?? this.showDangerZones,
      showSafeZones: showSafeZones ?? this.showSafeZones,
      showNetworkStrength: showNetworkStrength ?? this.showNetworkStrength,
      showOtherTourists: showOtherTourists ?? this.showOtherTourists,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      internetStatus: internetStatus ?? this.internetStatus,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      currentPosition: currentPosition ?? this.currentPosition,
      geofenceZones: geofenceZones ?? this.geofenceZones,
      triggeredDangerZone: clearDanger ? null : (triggeredDangerZone ?? this.triggeredDangerZone),
      triggeredSafeZone: clearSafe ? null : (triggeredSafeZone ?? this.triggeredSafeZone),
      triggeredWeatherZone: clearWeather ? null : (triggeredWeatherZone ?? this.triggeredWeatherZone),
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final GpsService _gpsService = GpsService();
  StreamSubscription<Position>? _gpsSubscription;

  MapNotifier() : super(const MapState()) {
    _initGps();
    _loadMockGeofences();
  }

  Future<void> _initGps() async {
    try {
      await _gpsService.requestPermission();
      final pos = await _gpsService.getCurrentPosition();
      state = state.copyWith(gpsStatus: GpsStatus.granted, currentPosition: pos);
      _startLocationListening();
    } catch (_) {
      state = state.copyWith(gpsStatus: GpsStatus.denied);
    }
  }

  void _startLocationListening() {
    _gpsSubscription?.cancel();
    _gpsSubscription = _gpsService.getLocationStream().listen(
      (position) {
        _handleLocationUpdate(position);
      },
      onError: (err) {
        // Handle error gracefully
      },
    );
  }

  void _handleLocationUpdate(Position position) {
    GeofenceZone? activeDanger;
    GeofenceZone? activeSafe;
    GeofenceZone? activeWeather;

    for (final zone in state.geofenceZones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= zone.radiusMeters) {
        if (zone.type == GeofenceType.danger) {
          activeDanger = zone;
        } else if (zone.type == GeofenceType.safe) {
          activeSafe = zone;
        } else if (zone.type == GeofenceType.weatherAlert) {
          activeWeather = zone;
        }
      }
    }

    state = state.copyWith(
      currentPosition: position,
      triggeredDangerZone: activeDanger,
      triggeredSafeZone: activeSafe,
      triggeredWeatherZone: activeWeather,
      clearDanger: activeDanger == null,
      clearSafe: activeSafe == null,
      clearWeather: activeWeather == null,
    );
  }

  /// Geofence data near Pune — with testing danger zone at the exact Pune default coordinates!
  void _loadMockGeofences() {
    state = state.copyWith(geofenceZones: const [
      GeofenceZone(
        id: 'danger_pune',
        label: 'Pune Metro Construction Site — High voltage danger & falling debris risk',
        latitude: 18.5204, // Exact Pune center coords to trigger geofence test immediately!
        longitude: 73.8567,
        radiusMeters: 150,
        type: GeofenceType.danger,
      ),
      GeofenceZone(
        id: 'danger_1',
        label: 'Restricted Area – Sinhagad Fort Edge',
        latitude: 18.3662,
        longitude: 73.7557,
        radiusMeters: 200,
        type: GeofenceType.danger,
      ),
      GeofenceZone(
        id: 'safe_1',
        label: 'Tourist Info Center – Shaniwar Wada',
        latitude: 18.5195,
        longitude: 73.8553,
        radiusMeters: 200,
        type: GeofenceType.safe,
      ),
      GeofenceZone(
        id: 'weather_1',
        label: 'Flash Flood Risk – Mulshi Dam Area',
        latitude: 18.5116,
        longitude: 73.5052,
        radiusMeters: 500,
        type: GeofenceType.weatherAlert,
      ),
    ]);
  }

  void toggleDangerZones(bool val) =>
      state = state.copyWith(showDangerZones: val);

  void toggleSafeZones(bool val) =>
      state = state.copyWith(showSafeZones: val);

  void toggleNetworkStrength(bool val) =>
      state = state.copyWith(showNetworkStrength: val);

  void toggleOtherTourists(bool val) =>
      state = state.copyWith(showOtherTourists: val);

  void zoomIn() =>
      state = state.copyWith(zoomLevel: (state.zoomLevel + 1).clamp(5.0, 20.0));

  void zoomOut() =>
      state = state.copyWith(zoomLevel: (state.zoomLevel - 1).clamp(5.0, 20.0));

  void setGpsDenied() =>
      state = state.copyWith(gpsStatus: GpsStatus.denied);

  void setGpsGranted() {
    state = state.copyWith(gpsStatus: GpsStatus.granted);
    _initGps();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
