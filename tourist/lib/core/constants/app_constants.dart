import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  /// Set to true to switch back to localhost / local emulator backend.
  static const bool useLocalBackend = false;

  /// Platform-aware backend base URL.
  /// Defaults to production Railway URL, falls back to platform-aware local URL if useLocalBackend is true.
  static String get backendBaseUrl {
    if (!useLocalBackend) {
      return 'https://edi-production-b35b.up.railway.app';
    }
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  static const String sosEndpoint = '/api/sos';
  static const String blockchainVerifyEndpoint = '/api/blockchain/verify';
  static const String geofenceZonesEndpoint = '/api/geofence/zones';
  
  static const String bleServiceUuid = 'TravelSure-SOS-v1';
  
  static const int sosHopMax = 5;
  static const int gpsIntervalNormal = 30; // seconds
  static const int gpsIntervalHighRisk = 10; // seconds
  static const int sosActivationHoldMs = 3000;
}
