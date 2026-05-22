import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import 'presentation/providers/sos_state.dart';

class AndroidAdvertiseSettings {
  final int advertiseMode;
  final int txPowerLevel;
  final bool connectable;
  final int timeout;

  const AndroidAdvertiseSettings({
    this.advertiseMode = 0, // ADVERTISE_MODE_LOW_POWER
    this.txPowerLevel = 3, // ADVERTISE_TX_POWER_HIGH
    this.connectable = false,
    this.timeout = 0,
  });
}

class DecodedBleSos {
  final String touristId;
  final double lat;
  final double lng;
  final int timestamp;
  final int hopCount;

  DecodedBleSos({
    required this.touristId,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.hopCount,
  });

  factory DecodedBleSos.fromBytes(Uint8List bytes) {
    if (bytes.length < 21) {
      throw FormatException('Payload size must be at least 21 bytes, got ${bytes.length}');
    }
    final bd = ByteData.sublistView(bytes);

    // Bytes 0-7: touristId (ASCII)
    final idBytes = bytes.sublist(0, 8);
    final touristId = ascii.decode(idBytes).trim();

    // Bytes 8-11: lat * 1e5 as Int32 big-endian
    final latFixed = bd.getInt32(8, Endian.big);
    final lat = latFixed / 100000.0;

    // Bytes 12-15: lng * 1e5 as Int32 big-endian
    final lngFixed = bd.getInt32(12, Endian.big);
    final lng = lngFixed / 100000.0;

    // Bytes 16-19: timestamp as Int32 big-endian
    final timestamp = bd.getInt32(16, Endian.big);

    // Byte 20: hopCount as Uint8
    final hopCount = bytes[20];

    return DecodedBleSos(
      touristId: touristId,
      lat: lat,
      lng: lng,
      timestamp: timestamp,
      hopCount: hopCount,
    );
  }
}

class SosLruCache {
  final List<String> _cache = [];
  final int maxEntries = 50;

  bool contains(String touristIdSub, int timestamp) {
    final key = '$touristIdSub-$timestamp';
    return _cache.contains(key);
  }

  void add(String touristIdSub, int timestamp) {
    final key = '$touristIdSub-$timestamp';
    if (_cache.contains(key)) {
      _cache.remove(key);
    }
    _cache.add(key);
    if (_cache.length > maxEntries) {
      _cache.removeAt(0);
    }
  }

  void clear() {
    _cache.clear();
  }
}

class BleSosService {
  static const MethodChannel _advertiseChannel = MethodChannel('traveltrek.tourist/ble_advertise');
  
  final SosLruCache _lruCache = SosLruCache();
  StreamSubscription? _scanSubscription;
  bool _isScanning = false;
  bool _isAdvertising = false;

  Function(Map<String, dynamic> payload)? onOnlineRelayRequest;

  // Derive Guid UUID from AppConstants.bleServiceUuid string
  Guid getSosServiceUuid() {
    final bytes = md5.convert(utf8.encode(AppConstants.bleServiceUuid)).bytes;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final uuidStr = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
    return Guid(uuidStr);
  }

  Future<bool> checkAdvertisePermissions() async {
    try {
      final bluetoothAdvGranted = await Permission.bluetoothAdvertise.request().isGranted;
      final bluetoothConnectGranted = await Permission.bluetoothConnect.request().isGranted;
      return bluetoothAdvGranted && bluetoothConnectGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkScanPermissions() async {
    try {
      final bluetoothScanGranted = await Permission.bluetoothScan.request().isGranted;
      final bluetoothConnectGranted = await Permission.bluetoothConnect.request().isGranted;
      final locationGranted = await Permission.location.request().isGranted;
      return bluetoothScanGranted && bluetoothConnectGranted && locationGranted;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------
  // BLE ADVERTISING
  // ----------------------------------------------------

  Future<void> startAdvertising({
    required Uint8List payload,
  }) async {
    assert(payload.length == 21, 'BLE payload must be 21 bytes');

    final hasPerms = await checkAdvertisePermissions();
    if (!hasPerms) {
      debugPrint('BLE Advertise: Permissions not granted.');
    }

    try {
      final serviceUuid = getSosServiceUuid().toString();
      const settings = AndroidAdvertiseSettings();

      debugPrint('BLE Advertising payload (21 bytes): $payload');
      debugPrint('BLE Advertising Service UUID: $serviceUuid');

      await _advertiseChannel.invokeMethod('startAdvertising', {
        'serviceUuid': serviceUuid,
        'payload': payload,
        'advertiseMode': settings.advertiseMode,
        'txPowerLevel': settings.txPowerLevel,
        'connectable': settings.connectable,
        'timeout': settings.timeout,
      });
      _isAdvertising = true;
    } catch (e) {
      debugPrint('Error starting native BLE advertisement: $e');
    }
  }

  Future<void> stopAdvertising() async {
    if (_isAdvertising) {
      try {
        await _advertiseChannel.invokeMethod('stopAdvertising');
      } catch (_) {}
      _isAdvertising = false;
    }
  }

  // ----------------------------------------------------
  // BLE MESH SCANNING (RELAY MODE)
  // ----------------------------------------------------

  Future<void> startScanning({
    required SosNotifier notifier,
  }) async {
    final hasPerms = await checkScanPermissions();
    if (!hasPerms) {
      notifier.setLayerStatus(LayerType.ble, SosLayerStatus.failed);
      return;
    }

    if (!await FlutterBluePlus.isSupported) {
      notifier.setLayerStatus(LayerType.ble, SosLayerStatus.failed);
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      notifier.setLayerStatus(LayerType.ble, SosLayerStatus.failed);
      return;
    }

    if (_isScanning) {
      await stopScanning();
    }

    final serviceUuid = getSosServiceUuid();
    notifier.setLayerStatus(LayerType.ble, SosLayerStatus.attempting);
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        timeout: const Duration(seconds: 30),
      );

      notifier.setLayerStatus(LayerType.ble, SosLayerStatus.success);

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final serviceData = result.advertisementData.serviceData[serviceUuid];
          if (serviceData != null && serviceData.length >= 21) {
            try {
              final payloadBytes = Uint8List.fromList(serviceData);
              _handleIncomingBlePayload(payloadBytes);
            } catch (e) {
              debugPrint('Error parsing service data payload: $e');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting BLE scan: $e');
      notifier.setLayerStatus(LayerType.ble, SosLayerStatus.failed);
      _isScanning = false;
    }
  }

  Future<void> stopScanning() async {
    if (_isScanning) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      _isScanning = false;
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void _handleIncomingBlePayload(Uint8List bytes) async {
    try {
      final decoded = DecodedBleSos.fromBytes(bytes);
      
      // Deduplication Key: touristId substring (0 to 8 bytes of payload) + timestamp
      final touristIdSub = decoded.touristId;
      final timestamp = decoded.timestamp;

      if (_lruCache.contains(touristIdSub, timestamp)) {
        debugPrint('BLE Mesh: SOS already seen (found in LRU cache). Skipping.');
        return;
      }

      // Add to LRU Cache
      _lruCache.add(touristIdSub, timestamp);

      // Check max hops
      if (decoded.hopCount >= AppConstants.sosHopMax) {
        debugPrint('Max hops reached — discarding SOS for $touristIdSub');
        return;
      }

      // Check internet connectivity
      bool isOnline = false;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        isOnline = !connectivityResult.contains(ConnectivityResult.none);
      } catch (_) {}

      // Get own touristId for relay
      String ownTouristId = '';
      try {
        final blockData = HiveService.blockchainBox.get('current_record');
        if (blockData != null) {
          ownTouristId = (blockData['tourist_id'] ?? blockData['touristId'] ?? '') as String;
        }
      } catch (_) {}

      if (isOnline) {
        debugPrint('Relaying SOS for $touristIdSub');
        if (onOnlineRelayRequest != null) {
          // Construct API payload for internet relay
          onOnlineRelayRequest!({
            'tourist_id': decoded.touristId,
            'lat': decoded.lat,
            'lng': decoded.lng,
            'timestamp': decoded.timestamp,
            'hop_count': decoded.hopCount,
            'relay_tourist_id': ownTouristId,
          });
        }
      } else {
        // Re-advertise with incremented hop count
        final nextHopCount = decoded.hopCount + 1;
        debugPrint('BLE Mesh: Re-broadcasting SOS for $touristIdSub (hop count: $nextHopCount)...');
        
        final reAdvPayload = buildBleSosPayload(
          touristId: decoded.touristId,
          lat: decoded.lat,
          lng: decoded.lng,
          timestamp: decoded.timestamp,
          hopCount: nextHopCount,
        );

        await startAdvertising(payload: reAdvPayload);
      }
    } catch (e) {
      debugPrint('Error processing BLE mesh packet: $e');
    }
  }
}

// Helper to build 21-byte binary payload
Uint8List buildBleSosPayload({
  required String touristId,
  required double lat,
  required double lng,
  required int timestamp,
  required int hopCount,
}) {
  final payload = Uint8List(21);
  final bd = ByteData.view(payload.buffer);

  // Bytes 0-7: touristId.substring(0,8) as ASCII
  final truncatedId = touristId.length >= 8 ? touristId.substring(0, 8) : touristId.padRight(8, ' ');
  final asciiBytes = ascii.encode(truncatedId);
  for (int i = 0; i < 8; i++) {
    payload[i] = asciiBytes[i];
  }

  // Bytes 8-11: lat * 1e5 as Int32 big-endian
  final latFixed = (lat * 100000.0).round();
  bd.setInt32(8, latFixed, Endian.big);

  // Bytes 12-15: lng * 1e5 as Int32 big-endian
  final lngFixed = (lng * 100000.0).round();
  bd.setInt32(12, lngFixed, Endian.big);

  // Bytes 16-19: timestamp as Int32 big-endian
  bd.setInt32(16, timestamp, Endian.big);

  // Byte 20: hop_count as Uint8
  payload[20] = hopCount;

  return payload;
}
