import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GpsStatus { granted, denied, loading }
enum InternetStatus { online, offline }

class MapState {
  final bool showDangerZones;
  final bool showSafeZones;
  final bool showNetworkStrength;
  final bool showOtherTourists;
  final GpsStatus gpsStatus;
  final InternetStatus internetStatus;
  final double zoomLevel;

  const MapState({
    this.showDangerZones = true,
    this.showSafeZones = true,
    this.showNetworkStrength = false,
    this.showOtherTourists = false,
    this.gpsStatus = GpsStatus.loading,
    this.internetStatus = InternetStatus.online,
    this.zoomLevel = 14.0,
  });

  MapState copyWith({
    bool? showDangerZones,
    bool? showSafeZones,
    bool? showNetworkStrength,
    bool? showOtherTourists,
    GpsStatus? gpsStatus,
    InternetStatus? internetStatus,
    double? zoomLevel,
  }) {
    return MapState(
      showDangerZones: showDangerZones ?? this.showDangerZones,
      showSafeZones: showSafeZones ?? this.showSafeZones,
      showNetworkStrength: showNetworkStrength ?? this.showNetworkStrength,
      showOtherTourists: showOtherTourists ?? this.showOtherTourists,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      internetStatus: internetStatus ?? this.internetStatus,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState()) {
    // Simulate GPS grant after brief delay
    _initGps();
  }

  Future<void> _initGps() async {
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(gpsStatus: GpsStatus.granted);
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

  void setGpsGranted() =>
      state = state.copyWith(gpsStatus: GpsStatus.granted);
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
