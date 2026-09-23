import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance =
      FirebaseMessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'amaterasu_notifications',
        'Amaterasu Trip',
        description: 'Notifiche di Amaterasu Trip',
        importance: Importance.high,
      );

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_androidChannel);

    _foregroundMessageSubscription ??=
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    debugPrint('FCM foreground listener registered');

    _messageOpenedAppSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    try {
      _token = await _messaging.getToken();

      if (_token != null) {
        debugPrint('FCM TEST TOKEN: $_token');
      } else {
        debugPrint('FCM token not available.');
      }
    } catch (error, stackTrace) {
      debugPrint('FCM token retrieval failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _tokenRefreshSubscription ??=
        _messaging.onTokenRefresh.listen(
          (token) {
            _token = token;
            debugPrint('FCM TEST TOKEN: $token');
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('FCM token refresh failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    debugPrint(
      'FCM foreground message received: ${message.messageId}',
    );

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'amaterasu_notifications',
        'Amaterasu Trip',
        channelDescription: 'Notifiche di Amaterasu Trip',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint(
      'FCM notification opened: ${message.messageId}',
    );

    debugPrint(
      'FCM notification data: ${message.data}',
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;

    await _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription = null;
  }
}