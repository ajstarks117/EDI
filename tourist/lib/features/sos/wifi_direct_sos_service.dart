import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import 'presentation/providers/sos_state.dart';

class WifiDirectSosService {
  final Nearby _nearby = Nearby();
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final List<String> _connectedEndpoints = [];
  bool _payloadSent = false;
  SosNotifier? _currentNotifier;

  Function(Map<String, dynamic> payload)? onOfflineRelayRequest;
  Function(Map<String, dynamic> payload)? onOnlineRelayRequest;

  Future<bool> checkAndRequestPermissions() async {
    try {
      final locationGranted = await Permission.location.request().isGranted;
      await Permission.nearbyWifiDevices.request().isGranted;

      final conn = await Connectivity().checkConnectivity();
      final wifiDisabled = conn.contains(ConnectivityResult.none);
      if (wifiDisabled) {
        debugPrint('WARNING: Wi-Fi might be disabled. Enable Wi-Fi (no internet needed) for emergency relay.');
      }

      return locationGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> startSosAdvertising({
    required SosNotifier notifier,
    required String touristId,
    required double lat,
    required double lng,
  }) async {
    _currentNotifier = notifier;
    _payloadSent = false;
    _connectedEndpoints.clear();

    final hasPerms = await checkAndRequestPermissions();
    if (!hasPerms) {
      notifier.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.failed);
      return;
    }

    notifier.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.attempting);

    final payloadMap = {
      'tourist_id': touristId,
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'hop_count': 0,
      'relay_tourist_id': null,
    };

    try {
      if (_isAdvertising) {
        await _nearby.stopAdvertising();
      }

      _isAdvertising = await _nearby.startAdvertising(
        touristId,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (endpointId, connectionInfo) async {
          debugPrint('Wi-Fi Direct connection initiated: $endpointId');
          try {
            await _nearby.acceptConnection(
              endpointId,
              onPayLoadRecieved: (endid, payload) {
                _handleIncomingPayload(payload, endid);
              },
            );
          } catch (e) {
            debugPrint('Error accepting connection: $e');
          }
        },
        onConnectionResult: (endpointId, status) async {
          debugPrint('Wi-Fi Direct connection result for $endpointId: $status');
          if (status == Status.CONNECTED) {
            _connectedEndpoints.add(endpointId);
            try {
              final jsonStr = jsonEncode(payloadMap);
              final bytes = Uint8List.fromList(utf8.encode(jsonStr));
              await _nearby.sendBytesPayload(endpointId, bytes);
              _payloadSent = true;
              _currentNotifier?.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.success);
            } catch (e) {
              debugPrint('Error sending payload: $e');
            }
          } else {
            _connectedEndpoints.remove(endpointId);
            if (_connectedEndpoints.isEmpty && !_payloadSent) {
              _currentNotifier?.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.failed);
            }
          }
        },
        onDisconnected: (endpointId) {
          _connectedEndpoints.remove(endpointId);
          if (_connectedEndpoints.isEmpty && !_payloadSent) {
            _currentNotifier?.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.failed);
          }
        },
        serviceId: AppConstants.bleServiceUuid,
      );

      if (!_isAdvertising) {
        notifier.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.failed);
      }
    } catch (e) {
      debugPrint('Error starting Wi-Fi Direct advertising: $e');
      notifier.setLayerStatus(LayerType.wifiDirect, SosLayerStatus.failed);
    }
  }

  Future<void> stopSosAdvertising() async {
    if (_isAdvertising) {
      try {
        await _nearby.stopAdvertising();
      } catch (_) {}
      _isAdvertising = false;
    }
    _connectedEndpoints.clear();
  }

  Future<void> startSosDiscovery() async {
    final hasPerms = await checkAndRequestPermissions();
    if (!hasPerms) {
      debugPrint('Wi-Fi Direct Discovery: permissions not granted');
      return;
    }

    try {
      if (_isDiscovering) {
        await _nearby.stopDiscovery();
      }

      _isDiscovering = await _nearby.startDiscovery(
        'TravelSure-Relay',
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, userName, serviceId) async {
          debugPrint('Found Wi-Fi Direct SOS beacon: $userName ($endpointId)');
          try {
            await _nearby.requestConnection(
              'TravelSure-Relay',
              endpointId,
              onConnectionInitiated: (endid, connectionInfo) async {
                try {
                  await _nearby.acceptConnection(
                    endid,
                    onPayLoadRecieved: (recendid, payload) {
                      _handleIncomingPayload(payload, recendid);
                    },
                  );
                } catch (e) {
                  debugPrint('Error accepting in discovery: $e');
                }
              },
              onConnectionResult: (endid, status) {
                debugPrint('Wi-Fi Direct discovery connection status: $status');
              },
              onDisconnected: (endid) {
                debugPrint('Wi-Fi Direct disconnected from $endid');
              },
            );
          } catch (e) {
            debugPrint('Error requesting connection: $e');
          }
        },
        onEndpointLost: (endpointId) {
          debugPrint('Lost endpoint: $endpointId');
        },
        serviceId: AppConstants.bleServiceUuid,
      );
    } catch (e) {
      debugPrint('Error starting Wi-Fi Direct discovery: $e');
    }
  }

  Future<void> stopSosDiscovery() async {
    if (_isDiscovering) {
      try {
        await _nearby.stopDiscovery();
      } catch (_) {}
      _isDiscovering = false;
    }
  }

  void _handleIncomingPayload(Payload payload, String endpointId) async {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final data = jsonDecode(jsonStr);
      if (data is Map<String, dynamic> && data.containsKey('tourist_id')) {
        debugPrint('Received SOS payload via Wi-Fi Direct from ${data['tourist_id']}');

        bool isOnline = false;
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          isOnline = !connectivityResult.contains(ConnectivityResult.none);
        } catch (_) {}

        if (isOnline) {
          debugPrint('Device is ONLINE. Relaying SOS for ${data['tourist_id']} via Layer 1...');
          if (onOnlineRelayRequest != null) {
            onOnlineRelayRequest!(data);
          }
        } else {
          debugPrint('Device is OFFLINE. Re-broadcasting SOS for ${data['tourist_id']} via Layer 4 BLE Mesh...');
          if (onOfflineRelayRequest != null) {
            String ownTouristId = '';
            try {
              final blockData = HiveService.blockchainBox.get('current_record');
              if (blockData != null) {
                ownTouristId = (blockData['tourist_id'] ?? blockData['touristId'] ?? '') as String;
              }
            } catch (_) {}

            final relayData = Map<String, dynamic>.from(data);
            relayData['relay_tourist_id'] = ownTouristId;
            relayData['hop_count'] = (relayData['hop_count'] ?? 0) + 1;
            onOfflineRelayRequest!(relayData);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing incoming payload: $e');
    }
  }
}
