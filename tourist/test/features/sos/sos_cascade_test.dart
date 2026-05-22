import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_sms/src/messages.g.dart';

import 'package:traveltrek_tourist_app/core/constants/app_constants.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/emergency_contact.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/sos/ble_sos_service.dart';
import 'package:traveltrek_tourist_app/features/sos/presentation/providers/sos_state.dart';
import 'package:traveltrek_tourist_app/features/sos/sos_service.dart';

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

class MockBattery implements Battery {
  final int mockLevel;
  MockBattery({this.mockLevel = 85});

  @override
  Future<int> get batteryLevel async => mockLevel;

  @override
  Stream<BatteryState> get onBatteryStateChanged => const Stream.empty();

  @override
  Future<BatteryState> get batteryState async => BatteryState.full;

  @override
  Future<bool> get isInBatterySaveMode async => false;
}

void main() {
  late Directory tempDir;
  const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  const String smsChannelName = 'dev.flutter.pigeon.flutter_sms.SmsHostApi.sendSms';

  final List<Map<String, dynamic>> sentSmsList = [];
  final List<String> connectivityResults = [];

  const mockProfile = TouristProfile(
    id: 'profile-id-999',
    phoneNumber: '+919876543210',
    fullName: 'John Doe',
    nationality: 'American',
    idType: 'Passport',
    idNumber: 'A12345678',
    profilePhotoUrl: 'https://example.com/photo.jpg',
    bloodGroup: 'O+',
    medicalConditions: 'None',
    emergencyContacts: [
      EmergencyContact(name: 'Jane Doe', phone: '+919999999999', relation: 'Spouse'),
      EmergencyContact(name: 'Jack Doe', phone: '+918888888888', relation: 'Brother'),
    ],
    languages: ['English', 'Spanish'],
    regionCode: 'US',
    isActive: true,
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup temporary hive directory
    tempDir = Directory('${Directory.current.path}/build/test_hive_sos');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    Hive.init(tempDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EmergencyContactAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TouristProfileAdapter());
    }

    // Open boxes
    await Hive.openBox<TouristProfile>('touristProfile');
    await Hive.openBox('blockchainId');

    // Populate Box Data
    final profileBox = Hive.box<TouristProfile>('touristProfile');
    await profileBox.put('current_profile', mockProfile);

    final blockchainBox = Hive.box('blockchainId');
    await blockchainBox.put('current_record', {
      'block_hash': '0xmockblockhash123',
      'tourist_id': 'TX-12345',
    });

    // Setup MethodChannel Mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      connectivityChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return connectivityResults;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      smsChannelName,
      (ByteData? message) async {
        const codec = SmsHostApi.pigeonChannelCodec;
        final args = codec.decodeMessage(message);
        String text = '';
        List<String> recipients = [];
        if (args is List) {
          if (args.isNotEmpty) {
            text = (args[0] ?? '') as String;
          }
          if (args.length > 1) {
            final recs = args[1];
            if (recs is List) {
              recipients = recs.cast<String>();
            }
          }
        }
        sentSmsList.add({
          'message': text,
          'recipients': recipients,
        });
        return codec.encodeMessage(<Object?>['sent']);
      },
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    // Clear Method Channel Mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(smsChannelName, null);
  });

  setUp(() {
    sentSmsList.clear();
    connectivityResults.clear();
    connectivityResults.add('wifi'); // default to online
  });

  group('SOS Cascade Engine (Layers 1 & 2) Tests', () {
    test('Layer 1 (Internet) Success case', () async {
      final notifier = SosNotifier();
      
      // Capture the request options to verify 3s timeout
      Duration? connectTimeout;
      Duration? receiveTimeout;

      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) async {
        connectTimeout = options.connectTimeout;
        receiveTimeout = options.receiveTimeout;
        
        final responsePayload = {'id': 'sos-server-999'};
        return ResponseBody.fromString(
          jsonEncode(responsePayload),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final sosService = SosService(dio: dio, battery: MockBattery(mockLevel: 88));

      await sosService.sendSosCascade(
        notifier: notifier,
        lat: 18.5204,
        lng: 73.8567,
      );

      // Verify Layer 1 success
      expect(notifier.state.layerInternet, equals(SosLayerStatus.success));
      expect(notifier.state.sosId, equals('sos-server-999'));

      // Verify Layer 2 (SMS) remains idle (terminated since Layer 1 succeeded)
      expect(notifier.state.layerSms, equals(SosLayerStatus.idle));
      expect(sentSmsList.isEmpty, isTrue);

      // Verify 3s timeout was strictly enforced
      expect(connectTimeout, equals(const Duration(seconds: 3)));
      expect(receiveTimeout, equals(const Duration(seconds: 3)));
    });

    test('Layer 1 Failure falling back to Layer 2 (SMS) Success case', () async {
      final notifier = SosNotifier();

      // Setup Layer 1 to fail
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) async {
        return ResponseBody.fromString(
          'Internal Server Error',
          500,
        );
      });

      final sosService = SosService(dio: dio, battery: MockBattery(mockLevel: 42));

      await sosService.sendSosCascade(
        notifier: notifier,
        lat: 18.5204,
        lng: 73.8567,
      );

      // Verify Layer 1 failed
      expect(notifier.state.layerInternet, equals(SosLayerStatus.failed));

      // Verify Layer 2 (SMS) succeeded
      expect(notifier.state.layerSms, equals(SosLayerStatus.success));

      // Verify the details of the sent SMS
      expect(sentSmsList.length, equals(1));
      
      final sms = sentSmsList.first;
      final String message = sms['message'] as String;
      final List<String> recipients = sms['recipients'] as List<String>;

      // Check Recipients: '100' first, then emergency contacts
      expect(recipients, equals(['100', '+919999999999', '+918888888888']));

      // Check SMS Content formatting:
      // 'TRAVELSURE EMERGENCY — [fullName] needs help at GPS: [lat],[lng] — TravelSure ID: [tourist_id] — Time: [timestamp]'
      expect(message, contains('TRAVELSURE EMERGENCY — John Doe needs help at GPS: 18.5204,73.8567'));
      expect(message, contains('TravelSure ID: TX-12345'));
      expect(message, contains('Time: '));
    });

    test('Offline connectivity sets payload state to offline and attempts both layers', () async {
      final notifier = SosNotifier();
      
      // Set connectivity to offline
      connectivityResults.clear();
      connectivityResults.add('none');

      Map<String, dynamic>? capturedPayload;

      final dio = Dio();
      dio.httpClientAdapter = MockAdapter((options) async {
        // Capture payload to verify connectivity field
        capturedPayload = options.data as Map<String, dynamic>?;
        return ResponseBody.fromString('Gateway Timeout', 504);
      });

      final sosService = SosService(dio: dio, battery: MockBattery(mockLevel: 65));

      await sosService.sendSosCascade(
        notifier: notifier,
        lat: 18.5204,
        lng: 73.8567,
      );

      // Verify payload connectivity field was 'offline'
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['connectivity'], equals('offline'));
      expect(capturedPayload!['battery_percent'], equals(65));
      expect(capturedPayload!['blockchain_id_hash'], equals('0xmockblockhash123'));

      // Verify fallback to SMS
      expect(notifier.state.layerInternet, equals(SosLayerStatus.failed));
      expect(notifier.state.layerSms, equals(SosLayerStatus.success));
      expect(sentSmsList.length, equals(1));
    });
  });

  group('BLE Mesh & WiFi Direct unit tests', () {
    test('BLE 21-byte Binary Payload Serialization & Deserialization', () {
      const touristId = 'TX-12345';
      const lat = 18.5204;
      const lng = 73.8567;
      const timestamp = 1716388800; // arbitrary timestamp
      const hopCount = 2;

      final payload = buildBleSosPayload(
        touristId: touristId,
        lat: lat,
        lng: lng,
        timestamp: timestamp,
        hopCount: hopCount,
      );

      // Verify length
      expect(payload.length, equals(21));

      // Deserialize
      final decoded = DecodedBleSos.fromBytes(payload);

      // Verify fields
      // touristId must be padded to 8 bytes in serialization, so 'TX-12345' becomes 'TX-12345 '
      expect(decoded.touristId, equals('TX-12345'));
      // Fixed point conversion loss is minimal:
      expect(decoded.lat, closeTo(lat, 0.00001));
      expect(decoded.lng, closeTo(lng, 0.00001));
      expect(decoded.timestamp, equals(timestamp));
      expect(decoded.hopCount, equals(hopCount));
    });

    test('BLE LRU Cache Deduplication & Eviction (> 50 entries)', () {
      final cache = SosLruCache();

      // Add 50 entries
      for (int i = 1; i <= 50; i++) {
        cache.add('user$i', 1000 + i);
      }

      // Check they exist
      expect(cache.contains('user1', 1001), isTrue);
      expect(cache.contains('user50', 1050), isTrue);

      // Add 51st entry
      cache.add('user51', 1051);

      // Verify oldest entry ('user1', 1001) has been evicted
      expect(cache.contains('user1', 1001), isFalse);
      
      // Verify other entries are still present
      expect(cache.contains('user2', 1002), isTrue);
      expect(cache.contains('user51', 1051), isTrue);

      // Re-add 'user2' to update its recency
      cache.add('user2', 1002);

      // Add 'user52' to trigger another eviction
      cache.add('user52', 1052);

      // 'user3' (now the oldest) should be evicted, but 'user2' should remain
      expect(cache.contains('user3', 1003), isFalse);
      expect(cache.contains('user2', 1002), isTrue);
    });

    test('BLE Mesh Hop Count boundaries', () {
      // Maximum hops should be 5 as per AppConstants.sosHopMax
      expect(AppConstants.sosHopMax, equals(5));

      // Test that buildBleSosPayload constructs correct hop count
      final payload = buildBleSosPayload(
        touristId: 'TX-12345',
        lat: 12.3456,
        lng: 78.9012,
        timestamp: 123456,
        hopCount: 5,
      );

      final decoded = DecodedBleSos.fromBytes(payload);
      expect(decoded.hopCount, equals(5));
    });
  });
}
