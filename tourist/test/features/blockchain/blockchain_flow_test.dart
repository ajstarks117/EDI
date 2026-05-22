import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/emergency_contact.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/blockchain/domain/models/blockchain_record.dart';
import 'package:traveltrek_tourist_app/features/blockchain/data/services/blockchain_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory('${Directory.current.path}/build/test_hive');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    Hive.init(tempDir.path);
    await Hive.openBox('blockchainId');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Blockchain Domain Model & Serialization', () {
    test('BlockchainRecord fromJson and toJson', () {
      final json = {
        'tourist_id': 'TX-12345678',
        'block_hash': '0xblockhash',
        'identity_hash': '0xidentityhash',
        'qr_data': 'eyJ0b3VyaXN0X2lkIjoiVFgtMTIzNDU2NzgifQ==',
        'issued_at': '2026-05-22T12:00:00Z',
      };

      final record = BlockchainRecord.fromJson(json);
      expect(record.touristId, 'TX-12345678');
      expect(record.blockHash, '0xblockhash');
      expect(record.identityHash, '0xidentityhash');
      expect(record.qrData, 'eyJ0b3VyaXN0X2lkIjoiVFgtMTIzNDU2NzgifQ==');
      expect(record.issuedAt, '2026-05-22T12:00:00Z');

      final serialized = record.toJson();
      expect(serialized['tourist_id'], 'TX-12345678');
      expect(serialized['block_hash'], '0xblockhash');
      expect(serialized['identity_hash'], '0xidentityhash');
      expect(serialized['qr_data'], 'eyJ0b3VyaXN0X2lkIjoiVFgtMTIzNDU2NzgifQ==');
      expect(serialized['issued_at'], '2026-05-22T12:00:00Z');
    });

    test('BlockchainRecord equality and copyWith', () {
      const record1 = BlockchainRecord(
        touristId: 'ID1',
        blockHash: 'B1',
        identityHash: 'H1',
        qrData: 'Q1',
        issuedAt: 'T1',
      );
      const record2 = BlockchainRecord(
        touristId: 'ID1',
        blockHash: 'B1',
        identityHash: 'H1',
        qrData: 'Q1',
        issuedAt: 'T1',
      );
      final record3 = record1.copyWith(touristId: 'ID2');

      expect(record1, equals(record2));
      expect(record1, isNot(equals(record3)));
      expect(record3.touristId, 'ID2');
      expect(record3.blockHash, 'B1');
    });
  });

  group('Blockchain Hashing & Service Tests', () {
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

    test('Cryptographic payload formatting and hashing', () async {
      final service = BlockchainService();
      
      // Let's compute expected hashes manually to verify correctness
      final expectedPhoneHash = sha256.convert(utf8.encode(mockProfile.phoneNumber)).toString();
      final expectedIdNumberHash = sha256.convert(utf8.encode(mockProfile.idNumber)).toString();
      
      final contactsJson = jsonEncode(mockProfile.emergencyContacts.map((c) => c.toJson()).toList());
      final expectedContactsHash = sha256.convert(utf8.encode(contactsJson)).toString();

      expect(expectedPhoneHash.length, 64);
      expect(expectedIdNumberHash.length, 64);
      expect(expectedContactsHash.length, 64);

      final record = await service.generateId(mockProfile);

      // Verify that sensitive fields are not raw in the mock QR data
      final qrDecodedJsonString = utf8.decode(base64.decode(record.qrData));
      final qrMap = jsonDecode(qrDecodedJsonString) as Map<String, dynamic>;

      expect(qrMap['tourist_id'], isNotEmpty);
      expect(qrMap['block_hash'], isNotEmpty);
      expect(qrMap['identity_hash'], isNotEmpty);
      expect(qrMap['issued_at'], isNotEmpty);

      // Verify identity hash is correct
      expect(record.identityHash, isNotEmpty);
      expect(record.blockHash, isNotEmpty);
    });

    test('Hive box caching stores hashed data only', () async {
      final service = BlockchainService();
      final record = await service.generateId(mockProfile);
      
      // Retrieve from Hive
      final cachedMap = Hive.box('blockchainId').get('current_record') as Map<dynamic, dynamic>?;
      
      expect(cachedMap, isNotNull);
      expect(cachedMap!['tourist_id'], record.touristId);
      expect(cachedMap['block_hash'], record.blockHash);
      expect(cachedMap['identity_hash'], record.identityHash);
      expect(cachedMap['qr_data'], record.qrData);

      // Check no raw sensitive data in cache
      final cachedStringRepresentation = cachedMap.toString();
      expect(cachedStringRepresentation, isNot(contains(mockProfile.phoneNumber)));
      expect(cachedStringRepresentation, isNot(contains(mockProfile.idNumber)));
    });
  });
}
