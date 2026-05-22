import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'gps_service.dart';
import '../../geofence/geofence_cache_service.dart';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      // 1. Initialize Hive for background process
      await Hive.initFlutter();

      if (taskName == GeofenceCacheService.geofenceRefreshTaskName) {
        try {
          final dio = Dio();
          final cacheService = GeofenceCacheService(dio: dio);
          await cacheService.fetchAndCacheZones();
        } catch (e) {
          debugPrint('Background geofence cache refresh failed: $e');
        }
        return Future.value(true);
      }

      final settingsBox = await Hive.openBox('settings');
      
      // Check if tracking is enabled in Settings
      final trackingEnabled = settingsBox.get('backtrackingEnabled', defaultValue: true);

      if (!trackingEnabled) {
        return Future.value(true);
      }

      // 2. Fetch current location
      final gpsService = GpsService();
      // Check permission first
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Future.value(true);
      }

      final position = await gpsService.getCurrentPosition();

      // 3. Storing offline log in Hive
      final logsBox = await Hive.openBox('location_logs');
      final logEntry = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      };
      await logsBox.add(logEntry);

      // 4. Try Syncing to Backend if online
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.none)) {
        final dio = Dio();
        
        final touristProfileBox = await Hive.openBox('tourist_profile');
        final profile = touristProfileBox.get('profile_data');
        final touristId = profile != null ? profile['phone'] ?? 'anonymous_tourist' : 'anonymous_tourist';
        final touristName = profile != null ? profile['name'] ?? 'Explorer' : 'Explorer';

        // Post location update
        await dio.post(
          'http://10.0.2.2:5000/api/emergency/sos', // SOS HTTP POST endpoint from authority backend
          data: {
            'touristId': touristId,
            'touristName': touristName,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'type': 'Live Backtracking Trace',
            'description': 'Periodic background location tracking trace.',
          },
          options: Options(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

        // Mark all logs as synced
        final unsyncedKeys = [];
        for (var key in logsBox.keys) {
          final log = logsBox.get(key);
          if (log != null && log['synced'] == 0) {
            unsyncedKeys.add(key);
          }
        }
        for (var key in unsyncedKeys) {
          final log = logsBox.get(key);
          if (log is Map) {
            final updatedLog = Map<String, dynamic>.from(log);
            updatedLog['synced'] = 1;
            await logsBox.put(key, updatedLog);
          }
        }
      }
    } catch (e) {
      debugPrint('Background location tracking failed: $e');
    }
    return Future.value(true);
  });
}

class BackgroundTrackingService {
  static const String trackingTaskName = "com.traveltrek.backtracking";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      backgroundCallbackDispatcher,
    );
  }

  static Future<void> startTracking() async {
    // Run periodically every 15 minutes (minimum allowed by Android OS)
    await Workmanager().registerPeriodicTask(
      "1",
      trackingTaskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> stopTracking() async {
    await Workmanager().cancelAll();
  }
}
