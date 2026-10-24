import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check after Firebase initialization.
/// Local emulator tests deliberately bypass remote attestation.
final class AmaterasuAppCheckBootstrap {
  static bool _ready = false;

  static bool get isReady => _ready;

  static const _siteKey = String.fromEnvironment(
    'AMATERASU_RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  static const _webDebug = bool.fromEnvironment(
    'AMATERASU_WEB_APP_CHECK_DEBUG',
    defaultValue: false,
  );

  static Future<void> initialize({required bool localFirebaseTest}) async {
    _ready = false;

    if (localFirebaseTest) {
      debugPrint('AMATERASU: App Check skipped for local emulators.');
      return;
    }

    if (kIsWeb) {
      if (!_webDebug && _siteKey.trim().isEmpty) {
        debugPrint(
          'AMATERASU: Web App Check not configured. '
          'Protected recovery is unavailable.',
        );
        return;
      }

      await FirebaseAppCheck.instance.activate(
        providerWeb: _webDebug
            ? WebDebugProvider()
            : ReCaptchaEnterpriseProvider(_siteKey),
      );

      _ready = true;
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );

      _ready = true;
      return;
    }

    debugPrint('AMATERASU: App Check not enabled on this platform.');
  }

  /// Protected operations must fail closed if not configured.
  static void requireReady() {
    if (!_ready) {
      throw StateError('Firebase App Check is not configured for this client.');
    }
  }

  /// Verifies a real token. Do not log or expose the token.
  static Future<bool> verifyToken() async {
    requireReady();

    final result = await FirebaseAppCheck.instance.getToken(true);

    return result != null && result.isNotEmpty;
  }
}
