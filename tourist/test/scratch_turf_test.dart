// ignore_for_file: avoid_print
import 'package:turf/turf.dart';

void main() {
  print("Testing turf geometries...");
  try {
    final coordinates = [
      [
        Position(0.0, 0.0),
        Position(0.0, 10.0),
        Position(10.0, 10.0),
        Position(10.0, 0.0),
        Position(0.0, 0.0),
      ]
    ];
    
    final polygon = Feature<Polygon>(
      geometry: Polygon(coordinates: coordinates),
    );
    
    final pointInside = Feature<Point>(
      geometry: Point(coordinates: Position(5.0, 5.0)),
    );
    
    final pointOutside = Feature<Point>(
      geometry: Point(coordinates: Position(15.0, 15.0)),
    );

    // Let's pass the Position objects
    bool inside1 = booleanPointInPolygon(pointInside.geometry!.coordinates, polygon);
    bool outside1 = booleanPointInPolygon(pointOutside.geometry!.coordinates, polygon);
    print("Inside: $inside1");
    print("Outside: $outside1");

  } catch (e, stack) {
    print("Error during test: $e");
    print(stack);
  }
}
