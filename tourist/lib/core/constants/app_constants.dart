import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  /// Platform-aware backend base URL.
  /// Android emulator uses 10.0.2.2 to reach host machine's localhost.
  /// iOS simulator and web use localhost directly.
  static String get backendBaseUrl {
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
