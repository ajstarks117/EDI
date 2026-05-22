import 'package:flutter/foundation.dart';
import 'package:turf/turf.dart';
import 'geofence_zone.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class GeofenceChecker {
  GeofenceChecker._();

  /// Check which geofence zones contain the given coordinate position.
  static List<GeofenceZone> checkPosition(LatLng position, List<GeofenceZone> zones) {
    final List<GeofenceZone> containingZones = [];

    // Turf uses Position(lng, lat)
    final pointPos = Position(position.longitude, position.latitude);

    for (final zone in zones) {
      if (!zone.isActive || zone.polygonCoordinates.isEmpty) {
        continue;
      }

      try {
        // Map List<List<double>> to List<Position>
        final List<Position> positions = zone.polygonCoordinates
            .map((coord) => Position(coord[0], coord[1]))
            .toList();

        // Turf requires the linear ring of the Polygon to be closed (first == last)
        if (positions.isNotEmpty && positions.first != positions.last) {
          positions.add(positions.first);
        }

        // A valid polygon ring needs at least 4 coordinates (3 unique vertices + closed endpoint)
        if (positions.length < 4) {
          continue;
        }

        final polygon = Feature<Polygon>(
          geometry: Polygon(coordinates: [positions]),
        );

        if (booleanPointInPolygon(pointPos, polygon)) {
          containingZones.add(zone);
        }
      } catch (e) {
        // Print/log the exception and keep processing other zones
        debugPrint('Geofence check error for zone [${zone.id}]: $e');
      }
    }

    return containingZones;
  }
}
