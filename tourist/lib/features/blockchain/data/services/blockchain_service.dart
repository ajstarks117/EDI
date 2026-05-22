import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:traveltrek_tourist_app/core/constants/app_constants.dart';
import 'package:traveltrek_tourist_app/core/services/hive_service.dart';
import 'package:traveltrek_tourist_app/features/auth/domain/models/tourist_profile.dart';
import 'package:traveltrek_tourist_app/features/blockchain/domain/models/blockchain_record.dart';

class BlockchainService {
  final Dio _dio;

  BlockchainService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConstants.backendBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

  String _sha256(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<BlockchainRecord> generateId(TouristProfile profile) async {
    // 1. Hash sensitive fields
    final phoneHash = _sha256(profile.phoneNumber);
    final idNumberHash = _sha256(profile.idNumber);
    
    // Hash list of emergency contacts
    final emergencyContactsJson = jsonEncode(profile.emergencyContacts.map((c) => c.toJson()).toList());
    final emergencyContactsHash = _sha256(emergencyContactsJson);

    // 2. Assemble identityPayload with keys in ALPHABETICAL order:
    // emergency_contacts_hash, full_name, id_document_type, id_number_hash, phone_hash, region_code, registration_timestamp
    final payloadMap = <String, dynamic>{
      'emergency_contacts_hash': emergencyContactsHash,
      'full_name': profile.fullName,
      'id_document_type': profile.idType,
      'id_number_hash': idNumberHash,
      'phone_hash': phoneHash,
      'region_code': profile.regionCode,
      'registration_timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    // Use SplayTreeMap to force alphabetical key order
    final sortedPayload = SplayTreeMap<String, dynamic>.from(payloadMap);
    final serializedPayload = jsonEncode(sortedPayload);
    
    // 3. Identity payload debug print in alphabetical order (emergency_contacts_hash comes before full_name)
    debugPrint('sortedPayload JSON: $serializedPayload');

    // Compute identityHash = sha256(jsonEncode(sortedPayload))
    final identityHash = _sha256(serializedPayload);
    debugPrint('Computed Identity Hash: $identityHash');

    try {
      // POST to Ajaya's backend /auth/register
      final response = await _dio.post(
        '/auth/register',
        data: sortedPayload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        // Create model
        final record = BlockchainRecord.fromJson(data);
        // Cache entire response in Hive
        await HiveService.blockchainBox.put('current_record', data);
        return record;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/register'),
          response: response,
        );
      }
    } catch (e) {
      debugPrint('Blockchain POST failed: $e. Falling back to Mock Receipt...');
      
      // Compute mock receipt
      final touristId = 'TX-${profile.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, 8).toUpperCase()}';
      final blockHash = '0x${_sha256(identityHash)}';
      final issuedAt = DateTime.now().toUtc().toIso8601String();
      
      final qrJsonMap = {
        'tourist_id': touristId,
        'block_hash': blockHash,
        'identity_hash': identityHash,
        'issued_at': issuedAt,
      };
      
      final qrJsonString = jsonEncode(qrJsonMap);
      final qrDataBase64 = base64.encode(utf8.encode(qrJsonString));

      final mockData = {
        'tourist_id': touristId,
        'block_hash': blockHash,
        'identity_hash': identityHash,
        'qr_data': qrDataBase64,
        'issued_at': issuedAt,
      };

      // Cache mock response in Hive
      await HiveService.blockchainBox.put('current_record', mockData);
      
      return BlockchainRecord.fromJson(mockData);
    }
  }

  BlockchainRecord? getCachedRecord() {
    final data = HiveService.blockchainBox.get('current_record');
    if (data != null) {
      return BlockchainRecord.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
}
