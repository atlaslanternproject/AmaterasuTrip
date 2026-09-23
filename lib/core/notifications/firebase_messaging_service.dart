import 'dart:async';

import '../localization/external_locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance =
      FirebaseMessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    debugPrint(
      'External notification locale: ${ExternalLocale.languageCode}',
    );

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
        await _registerCurrentToken();
      } else {
        debugPrint('FCM token not available.');
      }
    } catch (error, stackTrace) {
      debugPrint('FCM token retrieval failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _tokenRefreshSubscription ??=
        _messaging.onTokenRefresh.listen(
          (token) async {
            _token = token;
            debugPrint('FCM TEST TOKEN REFRESHED: $token');

            try {
              await _registerCurrentToken();
            } catch (error, stackTrace) {
              debugPrint('FCM refreshed token registration failed: $error');
              debugPrintStack(stackTrace: stackTrace);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('FCM token refresh failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> syncCurrentUserToken() async {
    try {
      await _registerCurrentToken();
    } catch (error, stackTrace) {
      debugPrint('FCM user token sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _registerCurrentToken() async {
    final user = _auth.currentUser;
    final token = _token;

    if (user == null || token == null) {
      return;
    }

    await _firestore.collection('viaggiatori').doc(user.uid).set({
      'fcmToken': token,
      'notificationLocale': ExternalLocale.languageCode,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint(
      'FCM token registered for user ${user.uid} '
      'with locale ${ExternalLocale.languageCode}',
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