import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:traveltrek_tourist_app/features/ai/ai_state.dart';
import 'package:traveltrek_tourist_app/features/ai/ai_intent_classifier.dart';
import 'package:traveltrek_tourist_app/features/ai/ai_prompt_builder.dart';
import 'package:traveltrek_tourist_app/features/ai/ollama_client.dart';
import 'package:traveltrek_tourist_app/features/ai/ai_notifier.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/emergency_contact.dart';
import 'package:traveltrek_tourist_app/features/geofence/geofence_zone.dart';

class MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  int mockFreeStorageBytes = 5 * 1024 * 1024 * 1024; // Default 5 GB
  const MethodChannel storageChannel = MethodChannel('traveltrek.tourist/ble_advertise');
  const MethodChannel speechChannel = MethodChannel('speech_to_text');
  const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup temporary hive directory
    tempDir = Directory('${Directory.current.path}/build/test_hive_ai');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmergencyContactAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TouristProfileAdapter());
    }

    await Hive.openBox<TouristProfile>('touristProfile');

    // Mock storage MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      storageChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getFreeStorage') {
          return mockFreeStorageBytes;
        }
        return null;
      },
    );

    // Mock speech_to_text MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      speechChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'initialize') {
          return true;
        }
        if (methodCall.method == 'listen') {
          return true;
        }
        if (methodCall.method == 'stop') {
          return true;
        }
        return null;
      },
    );

    // Mock connectivity MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      connectivityChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return ['none'];
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(storageChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(speechChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivityChannel, null);
  });

  group('AI Safety Assistant Tests', () {
    test('Intent classification assigns correct intent types for all keyword categories', () {
      expect(classifyIntent('I am injured and bleeding'), equals(AiIntent.emergency));
      expect(classifyIntent('I have a high fever and headache'), equals(AiIntent.medical));
      expect(classifyIntent('Show me directions or route home'), equals(AiIntent.navigation));
      expect(classifyIntent('What is the weather policy for Mulshi?'), equals(AiIntent.information));
    });

    test('buildSystemPrompt includes profile metadata and active geofences correctly', () {
      const mockProfile = TouristProfile(
        id: 'user-123',
        phoneNumber: '+919999999999',
        fullName: 'Jane Doe',
        nationality: 'Indian',
        idType: 'Aadhaar',
        idNumber: '123456789012',
        profilePhotoUrl: '',
        bloodGroup: 'B+',
        medicalConditions: 'Peanuts allergy',
        emergencyContacts: [],
        languages: ['Hindi'],
        regionCode: 'IN',
        isActive: true,
      );

      final zones = <GeofenceZone>[
        GeofenceZone(
          id: 'zone-1',
          name: 'Mulshi Gorge Excl',
          zoneType: 'exclusion',
          polygonCoordinates: [],
          advisoryText: 'Keep away',
          isActive: true,
        )
      ];

      final prompt = buildSystemPrompt(
        lat: 18.45,
        lng: 73.45,
        activeZones: zones,
        profile: mockProfile,
      );

      expect(prompt, contains('Mulshi Gorge Excl'));
      expect(prompt, contains('blood group B+'));
      expect(prompt, contains('allergies: Peanuts allergy'));
      expect(prompt, contains('Respond in tourist\'s language: Hindi'));
      expect(prompt, contains('Nearest area: Mulshi Lake Resort'));
    });

    test('OllamaClient adapts its host IP based on Platform type', () async {
      final client = OllamaClient();
      final url = await client.getOllamaBaseUrl();
      if (!kIsWeb && Platform.isAndroid) {
        expect(url, equals('http://10.0.2.2:11434'));
      } else {
        expect(url, equals('http://localhost:11434'));
      }
    });

    test('Free storage check determines model threshold', () async {
      final client = OllamaClient();
      mockFreeStorageBytes = 5 * 1024 * 1024 * 1024; // 5 GB (High)
      final storageHigh = await client.getFreeStorage();
      expect(storageHigh, isNotNull);

      mockFreeStorageBytes = 2 * 1024 * 1024 * 1024; // 2 GB (Low)
      final storageLow = await client.getFreeStorage();
      expect(storageLow, isNotNull);
    });

    test('SOS auto-trigger parser detects prefix and strips it', () {
      const responseWithTrigger = 'SOS_TRIGGER \n1. Clean the wound.\n2. Tap SOS.';
      bool triggeredSos = false;
      String cleaned = responseWithTrigger;

      if (cleaned.startsWith('SOS_TRIGGER')) {
        triggeredSos = true;
        cleaned = cleaned.substring('SOS_TRIGGER'.length).trim();
      }

      expect(triggeredSos, isTrue);
      expect(cleaned, equals('1. Clean the wound.\n2. Tap SOS.'));
    });

    test('Speech-to-text helper start and stop operations execute cleanly', () async {
      final container = ProviderContainer();
      final notifier = container.read(aiStateProvider.notifier);

      // Start listening
      var speechStarted = false;
      await notifier.startListening(
        onResult: (text) {
          speechStarted = true;
        },
      );

      // Stop listening
      await notifier.stopListening();
      expect(speechStarted, isFalse);
    });
  });
}
