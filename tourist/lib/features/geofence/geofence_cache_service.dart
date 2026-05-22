import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import 'geofence_zone.dart';

class GeofenceCacheService {
  static const String geofenceRefreshTaskName = "com.traveltrek.geofence.refresh";
  static const String geofenceBoxName = "geoFenceZones";

  final Dio _dio;

  GeofenceCacheService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches zones from the backend server and stores them in Hive.
  /// If offline or request fails, falls back to Hive cache silently.
  Future<List<GeofenceZone>> fetchAndCacheZones() async {
    try {
      final response = await _dio.get(
        '${AppConstants.backendBaseUrl}${AppConstants.geofenceZonesEndpoint}',
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200) {
        final rawData = response.data;
        List<dynamic> listData = [];
        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map && rawData.containsKey('data')) {
          final d = rawData['data'];
          if (d is List) {
            listData = d;
          }
        }

        final box = await Hive.openBox(geofenceBoxName);
        await box.clear();

        final List<GeofenceZone> zones = [];
        for (var item in listData) {
          if (item is Map) {
            final Map<String, dynamic> jsonItem = Map<String, dynamic>.from(item);
            final String? id = jsonItem['id']?.toString();
            if (id != null) {
              await box.put(id, jsonItem);
              zones.add(GeofenceZone.fromJson(jsonItem));
            }
          }
        }
        return zones;
      }
    } catch (e) {
      // Offline fallback: Serve cached zones silently
      debugPrint('Network fetch failed for geofences (offline mode): $e');
    }

    return getCachedZones();
  }

  /// Serves cached zones directly from the Hive box.
  Future<List<GeofenceZone>> getCachedZones() async {
    try {
      final box = await Hive.openBox(geofenceBoxName);
      final List<GeofenceZone> zones = [];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          zones.add(GeofenceZone.fromJson(Map<String, dynamic>.from(val)));
        }
      }
      return zones;
    } catch (e) {
      debugPrint('Hive geofence cache fetch error: $e');
      return [];
    }
  }
}
