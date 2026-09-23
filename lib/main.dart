import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('FCM background message received: ${message.messageId}');
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
  debugPrint("START USER: ${FirebaseAuth.instance.currentUser?.email}");
  runApp(const ProviderScope(child: AmaterasuTripApp()));
  unawaited(FirebaseMessagingService.instance.initialize());
}
