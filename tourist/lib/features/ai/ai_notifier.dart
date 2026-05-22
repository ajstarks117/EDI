import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/services/hive_service.dart';
import '../geofence/geofence_provider.dart';
import '../safety/services/gps_service.dart';
import 'ai_intent_classifier.dart';
import 'ai_prompt_builder.dart';
import 'ai_state.dart';
import 'ollama_client.dart';

class AiNotifier extends StateNotifier<AiState> {
  final Ref _ref;
  final OllamaClient _ollamaClient;
  final stt.SpeechToText _speech = stt.SpeechToText();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AiNotifier(this._ref, {OllamaClient? ollamaClient})
      : _ollamaClient = ollamaClient ?? OllamaClient(),
        super(AiState(
          messages: [
            AiMessage(
              role: 'assistant',
              text: "Hello! I'm your TravelSure Safety Assistant. I can help you with emergency guidance, safety tips, first aid, and navigation support — fully offline.\n\nTap a quick action below or describe your situation.",
              timestamp: DateTime.now(),
            )
          ],
        )) {
    _initConnectivity();
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      state = state.copyWith(mode: isOnline ? 'online' : 'offline');
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      state = state.copyWith(mode: isOnline ? 'online' : 'offline');
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiMessage(
      role: 'user',
      text: text,
      intent: classifyIntent(text),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      lastIntent: userMessage.intent,
    );

    try {
      // 1. Retrieve current location
      final pos = _ref.read(locationStreamProvider).value;
      final lat = pos?.latitude ?? 18.5204;
      final lng = pos?.longitude ?? 73.8567;

      // 2. Retrieve active zones
      final activeZones = _ref.read(geofenceProvider).activeZones;

      // 3. Retrieve tourist profile
      final profile = HiveService.profileBox.get('current_profile');

      // 4. Build system prompt
      final systemPrompt = buildSystemPrompt(
        lat: lat,
        lng: lng,
        activeZones: activeZones,
        profile: profile,
      );

      // 5. Generate AI response
      final response = await _ollamaClient.generate(
        prompt: text,
        systemPrompt: systemPrompt,
        isOnline: state.mode == 'online',
      );

      // 6. Check for SOS trigger prefix
      bool triggeredSos = false;
      String cleanedResponse = response;
      if (cleanedResponse.startsWith('SOS_TRIGGER')) {
        triggeredSos = true;
        cleanedResponse = cleanedResponse.substring('SOS_TRIGGER'.length).trim();
      }

      final assistantMessage = AiMessage(
        role: 'assistant',
        text: cleanedResponse,
        intent: userMessage.intent,
        timestamp: DateTime.now(),
        triggeredSos: triggeredSos,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error in AiNotifier sendMessage: $e');
      state = state.copyWith(
        messages: [
          ...state.messages,
          AiMessage(
            role: 'assistant',
            text: "I'm having trouble connecting. Please check your offline status or retry.",
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      bool available = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      if (available) {
        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
        );
      } else {
        debugPrint('Speech recognition not available');
      }
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  void clearConversation() {
    state = AiState(
      messages: [
        AiMessage(
          role: 'assistant',
          text: 'Conversation cleared. How can I help you stay safe?',
          timestamp: DateTime.now(),
        ),
      ],
      mode: state.mode,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _speech.stop();
    super.dispose();
  }
}

final aiStateProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref);
});

final aiProvider = aiStateProvider;
