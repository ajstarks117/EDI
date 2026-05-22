import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';

class AiAssistantNotifier extends StateNotifier<List<ChatMessage>> {
  AiAssistantNotifier() : super([
    ChatMessage(
      id: 'welcome',
      text: 'Hello! I\'m your TravelSure Safety Assistant. I can help you with emergency guidance, safety tips, and navigation support — even offline.\n\nTap a quick action below or type your concern.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  int _msgCounter = 0;

  void sendMessage(String text) {
    _msgCounter++;
    final userMsg = ChatMessage(
      id: 'user_$_msgCounter',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // Generate offline response
    Future.delayed(const Duration(milliseconds: 400), () {
      _msgCounter++;
      final response = _generateResponse(text);
      final aiMsg = ChatMessage(
        id: 'ai_$_msgCounter',
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, aiMsg];
    });
  }

  String _generateResponse(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('lost') || lower.contains('where am i')) {
      return '🧭 **Stay Calm — You\'re Not Alone**\n\n'
          '1. Stay where you are. Do NOT wander further.\n'
          '2. Open the Map tab to see your GPS coordinates.\n'
          '3. Look for landmarks — buildings, signs, rivers.\n'
          '4. Call Tourist Helpline: **1363**\n'
          '5. If no signal, enable Bluetooth mesh in the Map safety panel to alert nearby tourists.\n\n'
          'Your live location is being shared with your emergency contacts.';
    }

    if (lower.contains('medical') || lower.contains('hurt') || lower.contains('injury') || lower.contains('hospital')) {
      return '🏥 **Medical Emergency Protocol**\n\n'
          '1. Call Medical Emergency: **102** or National Emergency: **112**\n'
          '2. If bleeding, apply pressure with clean cloth.\n'
          '3. Do NOT move the injured person unless in immediate danger.\n'
          '4. Share your GPS location via the Map tab.\n'
          '5. Keep airways clear if unconscious.\n\n'
          'Stay on the line with emergency services until help arrives.';
    }

    if (lower.contains('weather') || lower.contains('storm') || lower.contains('flood') || lower.contains('rain')) {
      return '⛈️ **Severe Weather Advisory**\n\n'
          '1. Move indoors immediately — avoid open fields and tall trees.\n'
          '2. Stay away from rivers, streams, and low-lying areas.\n'
          '3. If driving, pull over and wait.\n'
          '4. Monitor the Map tab for weather alert markers.\n'
          '5. Call National Disaster Response: **1078**\n\n'
          'Keep your phone charged and stay connected.';
    }

    if (lower.contains('no network') || lower.contains('no signal') || lower.contains('offline')) {
      return '📡 **No Network Recovery Steps**\n\n'
          '1. Move to higher ground or open areas for better signal.\n'
          '2. Enable Airplane mode for 30 sec, then disable to re-scan towers.\n'
          '3. Use the SOS Bluetooth mesh broadcast to alert nearby devices.\n'
          '4. Your Digital ID and emergency data work fully offline.\n'
          '5. If at a tourist spot, look for Wi-Fi kiosks or ranger stations.\n\n'
          'Your last known location is cached and visible to authorities.';
    }

    if (lower.contains('fire') || lower.contains('smoke')) {
      return '🔥 **Fire Safety Protocol**\n\n'
          '1. Call Fire Department: **101** or National Emergency: **112**\n'
          '2. Move away from the fire — stay low to avoid smoke.\n'
          '3. Cover mouth and nose with wet cloth.\n'
          '4. Do NOT use elevators. Use stairs.\n'
          '5. Alert nearby people and move to open ground.\n\n'
          'Share your GPS location so rescue teams can find you quickly.';
    }

    return '🛡️ **Safety Tip**\n\n'
        'I can help you with:\n'
        '• **"I\'m lost"** — Navigation and GPS assistance\n'
        '• **"Medical emergency"** — First aid and hospital contacts\n'
        '• **"Severe weather"** — Storm/flood safety protocols\n'
        '• **"No network"** — Offline recovery steps\n'
        '• **"Fire"** — Fire emergency protocol\n\n'
        'Type your concern or tap a quick action button below.';
  }

  void clearConversation() {
    _msgCounter = 0;
    state = [
      ChatMessage(
        id: 'welcome',
        text: 'Conversation cleared. How can I help you stay safe?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, List<ChatMessage>>((ref) {
  return AiAssistantNotifier();
});
