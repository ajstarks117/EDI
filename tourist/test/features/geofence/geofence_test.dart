import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traveltrek_tourist_app/core/constants/app_constants.dart';
import 'package:traveltrek_tourist_app/features/geofence/geofence_zone.dart';
import 'package:traveltrek_tourist_app/features/geofence/geofence_checker.dart';
import 'package:traveltrek_tourist_app/features/geofence/geofence_provider.dart';
import 'package:traveltrek_tourist_app/features/geofence/geofence_cache_service.dart';
import 'package:traveltrek_tourist_app/features/safety/services/gps_service.dart';

class MockGpsService implements GpsService {
  final StreamController<Position> _controller = StreamController<Position>.broadcast();

  void emit(Position pos) {
    _controller.add(pos);
  }

  @override
  Stream<Position> getLocationStream({int intervalSeconds = 30}) {
    return _controller.stream;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({Duration? timeLimit}) async {
    return Position(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    return null;
  }
}

class FakeGeofenceCacheService extends GeofenceCacheService {
  final List<GeofenceZone> mockZones;
  FakeGeofenceCacheService(this.mockZones);

  @override
  Future<List<GeofenceZone>> fetchAndCacheZones() async {
    return mockZones;
  }

  @override
  Future<List<GeofenceZone>> getCachedZones() async {
    return mockZones;
  }
}

Position createPosition(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock local notifications and geolocator channel
  const MethodChannel notificationChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationChannel,
      (MethodCall methodCall) async {
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      geolocatorChannel,
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  group('GeofenceZone Model Tests', () {
    test('should parse from JSON and serialize to JSON correctly', () {
      final jsonMap = {
        'id': 'zone-1',
        'name': 'Red Zone Warning',
        'zoneType': 'warning',
        'polygonCoordinates': [
          [73.8567, 18.5204],
          [73.8567, 18.5304],
          [73.8667, 18.5304],
          [73.8667, 18.5204],
          [73.8567, 18.5204]
        ],
        'advisoryText': 'Stay inside hotel',
        'isActive': true,
      };

      final zone = GeofenceZone.fromJson(jsonMap);

      expect(zone.id, 'zone-1');
      expect(zone.name, 'Red Zone Warning');
      expect(zone.zoneType, 'warning');
      expect(zone.polygonCoordinates.length, 5);
      expect(zone.polygonCoordinates[0][0], 73.8567);
      expect(zone.advisoryText, 'Stay inside hotel');
      expect(zone.isActive, true);

      final serialized = zone.toJson();
      expect(serialized['id'], 'zone-1');
      expect(serialized['name'], 'Red Zone Warning');
      expect(serialized['zoneType'], 'warning');
      expect(serialized['polygonCoordinates'][0][0], 73.8567);
    });
  });

  group('GeofenceChecker Tests', () {
    final warningZone = GeofenceZone(
      id: 'z-warning',
      name: 'Warning Area',
      zoneType: 'warning',
      polygonCoordinates: [
        [0.0, 0.0],
        [0.0, 10.0],
        [10.0, 10.0],
        [10.0, 0.0],
      ],
      advisoryText: 'Keep safe',
      isActive: true,
    );

    test('Point inside polygon should be detected', () {
      const pointInside = LatLng(5.0, 5.0);
      final containing = GeofenceChecker.checkPosition(pointInside, [warningZone]);
      expect(containing.length, 1);
      expect(containing.first.id, 'z-warning');
    });

    test('Point outside polygon should not be detected', () {
      const pointOutside = LatLng(15.0, 15.0);
      final containing = GeofenceChecker.checkPosition(pointOutside, [warningZone]);
      expect(containing, isEmpty);
    });

    test('Auto-closes polygon coordinates if first and last differ', () {
      const pointEdge = LatLng(0.0, 0.0);
      final containing = GeofenceChecker.checkPosition(pointEdge, [warningZone]);
      expect(containing.length, 1);
    });
  });

  group('GeofenceNotifier State and Interval Adaptation Tests', () {
    late MockGpsService mockGps;
    late List<GeofenceZone> mockZones;
    late ProviderContainer container;

    setUp(() {
      mockGps = MockGpsService();
      mockZones = [
        GeofenceZone(
          id: 'z-warn',
          name: 'Warning Zone',
          zoneType: 'warning',
          polygonCoordinates: [
            [0.0, 0.0],
            [0.0, 10.0],
            [10.0, 10.0],
            [10.0, 0.0],
          ],
          advisoryText: 'Watch out',
          isActive: true,
        ),
        GeofenceZone(
          id: 'z-excl',
          name: 'Exclusion Zone',
          zoneType: 'exclusion',
          polygonCoordinates: [
            [20.0, 20.0],
            [20.0, 30.0],
            [30.0, 30.0],
            [30.0, 20.0],
          ],
          advisoryText: 'Do not enter',
          isActive: true,
        )
      ];

      container = ProviderContainer(
        overrides: [
          gpsServiceProvider.overrideWithValue(mockGps),
          geofenceProvider.overrideWith((ref) => GeofenceNotifier(
                ref,
                cacheService: FakeGeofenceCacheService(mockZones),
              )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state loading cached zones and listening to location', () async {
      // Trigger creation of notifier
      container.read(geofenceProvider);
      
      // Wait for cached zones to finish loading asynchronously
      await Future.delayed(const Duration(milliseconds: 20));

      final updatedState = container.read(geofenceProvider);
      expect(updatedState.allZones.length, 2);
      expect(updatedState.activeZones, isEmpty);
    });

    test('Entering warning zone updates active zones, resets acknowledgement, and adapts GPS interval', () async {
      container.read(geofenceProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // Emit coordinate inside warning zone (lat: 5.0, lng: 5.0)
      mockGps.emit(createPosition(5.0, 5.0));
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(geofenceProvider);
      expect(state.activeZones.length, 1);
      expect(state.activeZones.first.id, 'z-warn');
      expect(state.acknowledgedZoneIds, isEmpty);

      // Verify GPS interval set to high risk (10 seconds)
      final interval = container.read(gpsIntervalProvider);
      expect(interval, AppConstants.gpsIntervalHighRisk);
    });

    test('Acknowledging a zone adds it to acknowledged set', () async {
      container.read(geofenceProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      mockGps.emit(createPosition(5.0, 5.0));
      await Future.delayed(const Duration(milliseconds: 10));

      container.read(geofenceProvider.notifier).acknowledgeZone('z-warn');
      final state = container.read(geofenceProvider);
      expect(state.acknowledgedZoneIds.contains('z-warn'), isTrue);
    });

    test('Leaving risk zone updates active zones and reverts GPS interval to normal', () async {
      container.read(geofenceProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      // First enter risk zone
      mockGps.emit(createPosition(5.0, 5.0));
      await Future.delayed(const Duration(milliseconds: 10));

      // Move outside all zones
      mockGps.emit(createPosition(15.0, 15.0));
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(geofenceProvider);
      expect(state.activeZones, isEmpty);

      // Verify GPS interval reverted to normal (30 seconds)
      final interval = container.read(gpsIntervalProvider);
      expect(interval, AppConstants.gpsIntervalNormal);
    });
  });
}
