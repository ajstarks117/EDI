import '../auth/domain/models/tourist_profile.dart';
import '../geofence/geofence_zone.dart';

String reverseGeocode(double lat, double lng) {
  // Proximity check for key demo coordinates
  double distSq(double l1, double g1, double l2, double g2) {
    return (l1 - l2) * (l1 - l2) + (g1 - g2) * (g1 - g2);
  }

  if (distSq(lat, lng, 18.5204, 73.8567) < 0.005) {
    return 'Pune City Center';
  } else if (distSq(lat, lng, 18.45, 73.45) < 0.01) {
    return 'Mulshi Lake Resort';
  } else if (distSq(lat, lng, 18.75, 73.40) < 0.01) {
    return 'Lonavala Peak';
  } else if (distSq(lat, lng, 18.50, 73.40) < 0.01) {
    return 'Western Ghats Trail';
  }

  return 'Mulshi Valley Wilds';
}

String buildSystemPrompt({
  required double lat,
  required double lng,
  required List<GeofenceZone> activeZones,
  required TouristProfile? profile,
}) {
  final area = reverseGeocode(lat, lng);
  final activeZoneNames = activeZones.isEmpty
      ? 'None'
      : activeZones.map((z) => z.name).join(', ');

  final bloodGroup = (profile != null && profile.bloodGroup.isNotEmpty)
      ? profile.bloodGroup
      : 'Unknown';
  final allergies = (profile != null && profile.medicalConditions.isNotEmpty)
      ? profile.medicalConditions
      : 'None';
  final language = (profile != null && profile.languages.isNotEmpty)
      ? profile.languages.first
      : 'English';

  return '''
You are an offline emergency safety assistant for TravelTrek.
Your ONLY function is safety, first-aid, navigation, and emergency guidance.
Do not discuss any topic unrelated to tourist safety.
Tourist location: $lat, $lng. Nearest area: $area.
Active geo-fence zones: $activeZoneNames.
Tourist medical info: blood group $bloodGroup, allergies: $allergies.
Respond in tourist's language: $language.
For emergencies: respond in numbered steps, under 150 words unless first-aid.
CRITICAL: If user is in immediate danger, start response with SOS_TRIGGER.
''';
}
