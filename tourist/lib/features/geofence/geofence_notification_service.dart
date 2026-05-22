import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'geofence_zone.dart';

class GeofenceNotificationService {
  GeofenceNotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'geofence_alerts';
  static const String channelName = 'Geofence Alerts';
  static const String channelDesc = 'Alerts for entering geo-fence zones';

  /// Initialize notifications for the app.
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create high-importance channel for Android
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Request permissions dynamically for Android 13+ and iOS.
  static Future<void> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Handle notification tapping
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Geofence notification tapped: ${response.payload}');
    // Resuming the app will automatically trigger the global overlay if the user is in the zone.
  }

  /// Show standard notification when tourist enters a geofence zone
  static Future<void> showBackgroundAlert(GeofenceZone zone) async {
    String title = '';
    String body = '${zone.name}\n${zone.advisoryText}';

    switch (zone.zoneType.toLowerCase()) {
      case 'warning':
        title = '⚠️ CAUTION — Entered Warning Zone';
        break;
      case 'restricted':
        title = '🚨 WARNING — Exit Restricted Area';
        break;
      case 'exclusion':
        title = '🛑 DANGER — Exclusion Zone Entry';
        body = '${zone.name} - Immediate risk. Consider SOS.\n${zone.advisoryText}';
        break;
      default:
        title = '🔔 Zone Entry Alert';
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        zone.id.hashCode,
        title,
        body,
        platformDetails,
        payload: zone.id,
      );
    } catch (e) {
      debugPrint('Error showing geofence notification: $e');
    }
  }
}
