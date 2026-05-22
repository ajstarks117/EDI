class AppConstants {
  AppConstants._();

  static const String backendBaseUrl = 'http://localhost:3001';
  static const String sosEndpoint = '/api/sos'; // reserved for Ajaya
  static const String blockchainVerifyEndpoint = '/blockchain/verify';
  static const String geofenceZonesEndpoint = '/geofence/zones';
  
  static const String bleServiceUuid = 'TravelSure-SOS-v1';
  
  static const int sosHopMax = 5;
  static const int gpsIntervalNormal = 30; // seconds
  static const int gpsIntervalHighRisk = 10; // seconds
  static const int sosActivationHoldMs = 3000;
}
