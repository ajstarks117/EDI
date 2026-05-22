class GeofenceZone {
  final String id;
  final String name;
  final String zoneType; // warning, restricted, exclusion
  final List<List<double>> polygonCoordinates;
  final String advisoryText;
  final bool isActive;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.polygonCoordinates,
    required this.advisoryText,
    required this.isActive,
  });

  factory GeofenceZone.fromJson(Map<String, dynamic> json) {
    final List<List<double>> coords = [];
    final rawCoords = json['polygonCoordinates'];
    if (rawCoords is List) {
      for (var pointRaw in rawCoords) {
        if (pointRaw is List) {
          final List<double> point = [];
          for (var coordVal in pointRaw) {
            if (coordVal is num) {
              point.add(coordVal.toDouble());
            }
          }
          if (point.length >= 2) {
            coords.add(point);
          }
        }
      }
    }

    return GeofenceZone(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      zoneType: json['zoneType']?.toString() ?? '',
      polygonCoordinates: coords,
      advisoryText: json['advisoryText']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoneType': zoneType,
      'polygonCoordinates': polygonCoordinates,
      'advisoryText': advisoryText,
      'isActive': isActive,
    };
  }
}
