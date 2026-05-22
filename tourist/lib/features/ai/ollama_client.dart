import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class OllamaClient {
  final Dio _dio;

  OllamaClient({Dio? dio}) : _dio = dio ?? Dio();

  Future<String> getOllamaBaseUrl() async {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:11434';
    }
    return 'http://localhost:11434';
  }

  Future<int> getFreeStorage() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        const channel = MethodChannel('traveltrek.tourist/ble_advertise');
        final int? freeBytes = await channel.invokeMethod<int>('getFreeStorage');
        return freeBytes ?? 0;
      } catch (_) {
        return 0;
      }
    }
    return 10 * 1024 * 1024 * 1024; // Mock 10 GB on other platforms
  }

  Future<String> generate({
    required String prompt,
    required String systemPrompt,
    required bool isOnline,
  }) async {
    if (isOnline) {
      const url = '${AppConstants.backendBaseUrl}/ai/chat';
      try {
        final response = await _dio.post(
          url,
          data: {
            'message': '$systemPrompt\n\nUser query: $prompt',
            'prompt': '$systemPrompt\n\nUser query: $prompt',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': prompt}
            ]
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          if (data is Map) {
            final text = data['text'] ?? data['response'] ?? data['message'] ?? data['content'];
            if (text != null) return text.toString();
          }
          return response.data.toString();
        }
        throw Exception('Server returned status ${response.statusCode}');
      } catch (e) {
        debugPrint('Online AI chat failed, falling back to offline: $e');
        return _generateOffline(prompt, systemPrompt);
      }
    } else {
      return _generateOffline(prompt, systemPrompt);
    }
  }

  Future<String> _generateOffline(String prompt, String systemPrompt) async {
    final baseUrl = await getOllamaBaseUrl();
    final url = '$baseUrl/api/generate';

    final freeSpace = await getFreeStorage();
    final modelName = freeSpace > 4 * 1024 * 1024 * 1024 ? 'mistral' : 'phi';

    try {
      final response = await _dio.post(
        url,
        data: {
          'model': modelName,
          'prompt': '$systemPrompt\n\nUser query: $prompt',
          'stream': false,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final text = data['response'] ?? data['text'];
          if (text != null) return text.toString();
        }
        return response.data.toString();
      }
      throw Exception('Ollama server returned status ${response.statusCode}');
    } catch (e) {
      debugPrint('Ollama request failed, running mock simulation: $e');
      return _getSimulationFallback(prompt);
    }
  }

  String _getSimulationFallback(String prompt) {
    final lower = prompt.toLowerCase();

    // Check emergency keywords to trigger SOS activation recommended dialog
    if (lower.contains('injured') ||
        lower.contains('bleeding') ||
        lower.contains('trapped') ||
        lower.contains('snake') ||
        lower.contains('cannot move') ||
        lower.contains("can't move") ||
        lower.contains('accident') ||
        lower.contains('unconscious')) {
      return 'SOS_TRIGGER \n🚨 EMERGENCY FIRST-AID GUIDANCE\n\n1. Keep pressure on wound.\n2. Keep victim warm.\n3. Activate emergency beacon.';
    }

    if (lower.contains('lost') || lower.contains('where') || lower.contains('directions') || lower.contains('route')) {
      return '🗺️ NAVIGATION SUPPORT\n\n1. Stop walking.\n2. Check GPS signal.\n3. Turn on Bluetooth mesh relays.';
    }

    if (lower.contains('sick') || lower.contains('fever') || lower.contains('headache') || lower.contains('pain')) {
      return '🏥 MEDICAL FIRST-AID\n\n1. Sip fluids slowly.\n2. Rest in shaded zone.\n3. Take paracetamol if available.';
    }

    return 'ℹ️ GENERAL SAFETY INFORMATION\n\n1. Stay on designated trails.\n2. Report hazards via app.\n3. Keep powerbank connected.';
  }
}
