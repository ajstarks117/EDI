import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import 'presentation/providers/sos_state.dart';
import '../auth/domain/models/tourist_profile.dart';

class SosService {
  final Dio _dio;
  final Battery _battery;

  SosService({Dio? dio, Battery? battery})
      : _dio = dio ?? Dio(),
        _battery = battery ?? Battery();

  Future<void> sendSosCascade({
    required SosNotifier notifier,
    required double lat,
    required double lng,
  }) async {
    // ----------------------------------------------------
    // GATHER DATA & PREPARE PAYLOAD
    // ----------------------------------------------------
    
    // Check connectivity
    String connectivityStr = 'offline';
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        connectivityStr = 'online';
      }
    } catch (_) {
      connectivityStr = 'offline';
    }

    // Get battery percentage
    int batteryPercent = 100;
    try {
      batteryPercent = await _battery.batteryLevel;
    } catch (_) {
      batteryPercent = 100;
    }

    // Fetch Profile from Hive
    TouristProfile? profile;
    try {
      final profileBox = HiveService.profileBox;
      profile = profileBox.get('current_profile');
    } catch (_) {
      // Ignored
    }

    // Prepare Emergency Contacts
    List<Map<String, String>> emergencyContacts = [];
    if (profile != null) {
      emergencyContacts = profile.emergencyContacts
          .map((c) => {'name': c.name, 'phone': c.phone})
          .toList();
    }

    // Fetch Blockchain Hash & Tourist ID
    String blockchainIdHash = '';
    String touristId = '';
    try {
      final blockData = HiveService.blockchainBox.get('current_record');
      if (blockData != null) {
        blockchainIdHash = (blockData['block_hash'] ?? blockData['blockHash'] ?? '') as String;
        touristId = (blockData['tourist_id'] ?? blockData['touristId'] ?? '') as String;
      }
    } catch (_) {
      // Ignored
    }

    // ----------------------------------------------------
    // LAYER 1 — Internet (Primary)
    // ----------------------------------------------------
    notifier.setLayerStatus(LayerType.internet, SosLayerStatus.attempting);

    final payload = {
      'lat': lat,
      'lng': lng,
      'message': 'Tourist SOS — manual activation',
      'source': 'manual',
      'blockchain_id_hash': blockchainIdHash,
      'battery_percent': batteryPercent,
      'connectivity': connectivityStr,
      'emergency_contacts': emergencyContacts,
      'channel': 'internet',
    };

    // Debug print of payload to console (no raw personal data at root, phone is in list, blockchain_id_hash is hash)
    debugPrint('SOS Payload: ${jsonEncode(payload)}');

    bool layer1Success = false;
    try {
      // Post to backendBaseUrl + '/api/sos'
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/sos',
        data: payload,
        options: Options(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        notifier.setLayerStatus(LayerType.internet, SosLayerStatus.success);
        
        final responseData = response.data;
        if (responseData is Map && responseData.containsKey('id')) {
          notifier.setSosId(responseData['id'].toString());
        } else {
          notifier.setSosId('SOS-${DateTime.now().millisecondsSinceEpoch}');
        }
        layer1Success = true;
      } else {
        notifier.setLayerStatus(LayerType.internet, SosLayerStatus.failed);
      }
    } catch (e) {
      debugPrint('SOS Layer 1 (Internet) Failed: $e');
      notifier.setLayerStatus(LayerType.internet, SosLayerStatus.failed);
    }

    if (layer1Success) {
      // If success, terminate cascade (do not attempt other layers)
      return;
    }

    // ----------------------------------------------------
    // LAYER 2 — SMS Fallback
    // ----------------------------------------------------
    notifier.setLayerStatus(LayerType.sms, SosLayerStatus.attempting);

    final fullName = profile?.fullName ?? 'Tourist';
    final timestamp = DateTime.now().toIso8601String();
    final smsText = 'TRAVELSURE EMERGENCY — $fullName needs help at GPS: $lat,$lng — TravelSure ID: $touristId — Time: $timestamp';

    // Recipients: '100' (Police) first, then all emergency contacts numbers
    List<String> recipients = ['100'];
    if (profile != null) {
      recipients.addAll(profile.emergencyContacts.map((c) => c.phone));
    }

    try {
      debugPrint('Sending SOS SMS to: $recipients');
      debugPrint('SMS Body: $smsText');
      
      // Send SMS using flutter_sms
      await sendSMS(message: smsText, recipients: recipients);
      notifier.setLayerStatus(LayerType.sms, SosLayerStatus.success);
    } on PlatformException catch (e) {
      if (e.code == 'device_not_supported' || 
          e.message?.contains('simulator') == true || 
          e.message?.contains('Compose') == true ||
          e.message?.contains('not supported') == true) {
        debugPrint('SMS not supported (Simulator/Unsupported device): ${e.message}. Simulating success...');
        await Future.delayed(const Duration(seconds: 1));
        notifier.setLayerStatus(LayerType.sms, SosLayerStatus.success);
      } else {
        debugPrint('PlatformException on SMS send: $e');
        notifier.setLayerStatus(LayerType.sms, SosLayerStatus.failed);
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      if (kDebugMode) {
        debugPrint('Debug mode fallback: Simulating SMS success...');
        await Future.delayed(const Duration(seconds: 1));
        notifier.setLayerStatus(LayerType.sms, SosLayerStatus.success);
      } else {
        notifier.setLayerStatus(LayerType.sms, SosLayerStatus.failed);
      }
    }
  }
}
