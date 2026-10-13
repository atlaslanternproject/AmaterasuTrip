import 'dart:convert';

import 'device_enrollment_request.dart';

/// Saves PUBLIC pending-enrollment requests in device-local storage.
/// Does not authorise the device or store private keys.
final class PersistentDeviceEnrollmentRequest {
  PersistentDeviceEnrollmentRequest({required this.read, required this.write});

  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  Future<DeviceEnrollmentRequest> obtain({
    required String uid,
    required String deviceId,
    required List<int> x25519PublicKey,
    required List<int> ed25519PublicKey,
    required DateTime nowUtc,
  }) async {
    if (uid.trim().isEmpty || uid.length > 128) {
      throw ArgumentError('Invalid enrollment account.');
    }

    final key =
        'pending_enrollment_request_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';

    final now = nowUtc.toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final saved = await read(key);

    if (saved != null) {
      late final Map<String, dynamic> record;

      try {
        final decoded = jsonDecode(saved);

        if (decoded is! Map<String, dynamic> ||
            decoded.length != 3 ||
            decoded['version'] != 1 ||
            decoded['payload'] is! String ||
            decoded['expiresAtMs'] is! int) {
          throw const FormatException('Invalid pending enrollment record.');
        }

        record = decoded;
      } on FormatException {
        rethrow;
      } catch (_) {
        throw const FormatException('Corrupt pending enrollment record.');
      }

      final expiry = record['expiresAtMs'] as int;

      if (expiry <= 1) {
        throw const FormatException('Invalid enrollment expiration.');
      }

      // Validate an expired request immediately before its expiry,
      // without accepting it as an active request.
      final validationTime = nowMs >= expiry
          ? DateTime.fromMillisecondsSinceEpoch(expiry - 1, isUtc: true)
          : now;

      final previous = DeviceEnrollmentRequest.fromQrPayload(
        record['payload'] as String,
        expectedUserUid: uid,
        nowUtc: validationTime,
      );

      if (previous.expiresAtMs != expiry ||
          previous.newDeviceId != deviceId ||
          !_equal(previous.x25519PublicKey, x25519PublicKey) ||
          !_equal(previous.ed25519PublicKey, ed25519PublicKey)) {
        throw const FormatException(
          'Pending request does not match the device identity.',
        );
      }

      if (nowMs < expiry) {
        return previous;
      }
    }

    final request = await DeviceEnrollmentRequest.create(
      userUid: uid,
      newDeviceId: deviceId,
      x25519PublicKey: x25519PublicKey,
      ed25519PublicKey: ed25519PublicKey,
      nowUtc: now,
    );

    final encoded = jsonEncode({
      'version': 1,
      'payload': request.toQrPayload(),
      'expiresAtMs': request.expiresAtMs,
    });

    await write(key, encoded);

    if (await read(key) != encoded) {
      throw StateError('Pending request persistence failed.');
    }

    return request;
  }
}
