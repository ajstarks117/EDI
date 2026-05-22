enum AiIntent {
  emergency,
  medical,
  navigation,
  information,
}

class AiMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  final AiIntent? intent;
  final DateTime timestamp;
  final bool triggeredSos;

  const AiMessage({
    required this.role,
    required this.text,
    this.intent,
    required this.timestamp,
    this.triggeredSos = false,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'intent': intent?.name,
        'timestamp': timestamp.toIso8601String(),
        'triggeredSos': triggeredSos,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final intentStr = json['intent'] as String?;
    final intent = intentStr != null
        ? AiIntent.values.firstWhere((e) => e.name == intentStr)
        : null;
    return AiMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      intent: intent,
      timestamp: DateTime.parse(json['timestamp'] as String),
      triggeredSos: json['triggeredSos'] as bool? ?? false,
    );
  }
}

class AiState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String mode; // 'online' or 'offline'
  final AiIntent? lastIntent;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.mode = 'offline',
    this.lastIntent,
  });

  AiState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? mode,
    AiIntent? lastIntent,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      lastIntent: lastIntent ?? this.lastIntent,
    );
  }
}
