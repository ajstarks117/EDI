// lib/features/tracking/models/location_event.dart
enum ConnectivityState { online, offline }

class LocationEvent {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double altitudeMeters;
  final double speedKmh;
  final ConnectivityState connectivityState;
  final DateTime recordedAt;

  LocationEvent({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.altitudeMeters,
    required this.speedKmh,
    required this.connectivityState,
    required this.recordedAt,
  });
}
