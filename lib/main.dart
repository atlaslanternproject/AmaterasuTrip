import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'core/security/firebase_app_check_bootstrap.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'core/maps/google_maps_loader.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

const bool _localFirebaseTest = bool.fromEnvironment(
  'AMATERASU_LOCAL_TEST',
  defaultValue: false,
);

const FirebaseOptions _localFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSy000000000000000000000000000000000',
  appId: '1:123456789000:android:0123456789abcdef',
  messagingSenderId: '123456789000',
  projectId: 'demo-amaterasu-security',
);

Future<void> _configureFirebase() async {
  if ((appFlavor == 'localtest') != _localFirebaseTest) {
    throw StateError('Android flavor and Firebase TEST mode do not match.');
  }

  if (!_localFirebaseTest) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return;
  }

  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    throw StateError('Firebase TEST is supported only on Android.');
  }

  await Firebase.initializeApp(options: _localFirebaseOptions);

  final options = Firebase.app().options;

  if (options.projectId != 'demo-amaterasu-security' ||
      options.appId != '1:123456789000:android:0123456789abcdef') {
    throw StateError('Firebase TEST project mismatch.');
  }

  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 19099);

  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 18080);

  FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  ).useFunctionsEmulator('127.0.0.1', 15001);

  debugPrint('AMATERASU TEST: Firebase demo emulators configured.');
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (_localFirebaseTest) {
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('FCM background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureFirebase();
  await AmaterasuAppCheckBootstrap.initialize(
    localFirebaseTest: _localFirebaseTest,
  );
  if (!_localFirebaseTest) {
    // AMATERASU_WEB_MAPS_NONBLOCKING_V1
    // Maps must never block the initial Flutter screen.
    if (kIsWeb) {
      unawaited(
        initializeGoogleMaps().catchError(
          (Object error, StackTrace stackTrace) {
            debugPrint('Google Maps initialization failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        ),
      );
    } else {
      await initializeGoogleMaps();
    }
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }
  debugPrint("START USER: ${FirebaseAuth.instance.currentUser?.email}");
  runApp(const ProviderScope(child: AmaterasuTripApp()));
  if (!kIsWeb && !_localFirebaseTest) {
    unawaited(FirebaseMessagingService.instance.initialize());
  }
}
