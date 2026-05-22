import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';

class GpsService {
  Future<LocationPermission> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return permission;
  }

  Future<Position> getCurrentPosition({Duration? timeLimit}) async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: timeLimit,
    );
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getLocationStream({int intervalSeconds = 30}) {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: intervalSeconds),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers for GPS Service
// ---------------------------------------------------------------------------

final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());

final gpsIntervalProvider = StateProvider<int>((ref) => AppConstants.gpsIntervalNormal);

final locationStreamProvider = StreamProvider<Position>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  final interval = ref.watch(gpsIntervalProvider);
  return gpsService.getLocationStream(intervalSeconds: interval);
});

class GpsActiveNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _lastEmission;

  GpsActiveNotifier(this._ref) : super(false) {
    _listenToGps();
  }

  void _listenToGps() {
    _ref.listen<AsyncValue<Position>>(locationStreamProvider, (previous, next) {
      if (next.hasValue) {
        _lastEmission = DateTime.now();
        state = true;
        _startTimer();
      }
    }, fireImmediately: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastEmission == null) {
        state = false;
        timer.cancel();
      } else {
        final difference = DateTime.now().difference(_lastEmission!);
        if (difference.inSeconds > 60) {
          state = false;
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gpsActiveProvider = StateNotifierProvider<GpsActiveNotifier, bool>((ref) {
  return GpsActiveNotifier(ref);
});

