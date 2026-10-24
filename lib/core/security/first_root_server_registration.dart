import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_app_check_bootstrap.dart';

/// Registers the first signed identity using the protected server callable.
/// No plaintext private keys or recovery secrets are sent.
final class FirstRootServerRegistration {
  FirstRootServerRegistration({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  /// The server may have committed before the response was lost.
  static bool mayHaveCommitted(String code) {
    return const {
      'already-exists',
      'unavailable',
      'deadline-exceeded',
      'unknown',
    }.contains(code);
  }

  static void requireReceipt({
    required Object? response,
    required String deviceId,
    required String fingerprint,
  }) {
    if (response is! Map ||
        response.length != 2 ||
        response['deviceId'] != deviceId ||
        response['fingerprint'] != fingerprint) {
      throw StateError('Invalid first-root server receipt.');
    }
  }

  /// Exact comparison of the signed public root and encrypted backup.
  /// Never pin an unrelated root returned by the backend.
  static bool matchesServerRecord({
    required Map<String, dynamic> expected,
    required Map<String, dynamic>? actual,
  }) {
    if (actual == null ||
        actual.length != expected.length ||
        !expected.keys.every(actual.containsKey)) {
      return false;
    }

    for (final entry in expected.entries) {
      final remoteValue = actual[entry.key];
      final expectedValue = entry.value;

      if (expectedValue is Map) {
        if (remoteValue is! Map ||
            remoteValue.length != expectedValue.length ||
            !expectedValue.keys.every(remoteValue.containsKey)) {
          return false;
        }

        for (final key in expectedValue.keys) {
          if (remoteValue[key] != expectedValue[key]) {
            return false;
          }
        }
      } else if (remoteValue != expectedValue) {
        return false;
      }
    }

    return true;
  }

  Future<void> register({
    required Map<String, dynamic> root,
    required String expectedDeviceId,
    required String expectedFingerprint,
  }) async {
    // No debug-token creation or App Check bypass.
    AmaterasuAppCheckBootstrap.requireReady();

    if (root['deviceId'] != expectedDeviceId ||
        root['fingerprint'] != expectedFingerprint ||
        root.containsKey('privateKey') ||
        root.containsKey('recoveryCode')) {
      throw StateError('Unsafe root registration request.');
    }

    final callable = _functions.httpsCallable(
      'registerFirstE2eeRoot',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final response = await callable.call(<String, dynamic>{'root': root});

    requireReceipt(
      response: response.data,
      deviceId: expectedDeviceId,
      fingerprint: expectedFingerprint,
    );
  }
}
