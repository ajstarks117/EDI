import 'ai_state.dart';

AiIntent classifyIntent(String userMessage) {
  final msg = userMessage.toLowerCase();

  // EMERGENCY keywords: injured, trapped, attack, snake, bleeding, fire, accident, drowning, can't move, unconscious
  final emergencyKeywords = [
    'injured',
    'trapped',
    'attack',
    'snake',
    'bleeding',
    'fire',
    'accident',
    'drowning',
    "can't move",
    'unconscious',
  ];
  if (emergencyKeywords.any((kw) => msg.contains(kw))) {
    return AiIntent.emergency;
  }

  // MEDICAL keywords: sick, vomiting, fever, headache, altitude, pain
  final medicalKeywords = [
    'sick',
    'vomiting',
    'fever',
    'headache',
    'altitude',
    'pain',
  ];
  if (medicalKeywords.any((kw) => msg.contains(kw))) {
    return AiIntent.medical;
  }

  // NAVIGATION keywords: lost, directions, route, where, how far
  final navigationKeywords = [
    'lost',
    'directions',
    'route',
    'where',
    'how far',
  ];
  if (navigationKeywords.any((kw) => msg.contains(kw))) {
    return AiIntent.navigation;
  }

  return AiIntent.information;
}
