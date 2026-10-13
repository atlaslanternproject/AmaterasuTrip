import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'first_device_trust_anchor.dart';

/// Locally pinned identity of the user's first trusted device.
///
/// This pin must not be replaced just because Firebase returns a
/// different trust anchor. Missing pins require a separate enrollment
/// or recovery decision, never automatic trust in a remote key.
class AndroidFirstDeviceTrustPinStorage {
  AndroidFirstDeviceTrustPinStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(
              storageNamespace: 'amaterasu_health_keys_v1',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;
  final FirstDeviceTrustAnchorService _anchors =
      FirstDeviceTrustAnchorService();

  void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Android trust pin storage required.');
    }
  }

  String _keyName(String uid) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((value) => value < 32)) {
      throw ArgumentError('Invalid user UID.');
    }

    return 'first_device_trust_pin_v1_${base64UrlEncode(utf8.encode(uid))}';
  }

  /// Pins a locally issued identity. The caller must obtain the signing
  /// key from the authenticated local identity storage, not Firebase.
  ///
  /// The first-device bootstrap decision and proof of possession of
  /// the associated X25519 key are separate protocol requirements.
  ///
  /// This read-before-write guard is not an atomic compare-and-set.
  Future<String> pinLocallyIssuedRoot({
    required FirstDeviceTrustAnchor anchor,
    required SimpleKeyPair localSigningKey,
  }) async {
    _requireAndroid();

    final key = _keyName(anchor.userUid);

    if (await _storage.read(key: key) != null) {
      throw StateError('A first-device trust pin already exists.');
    }

    final signed = await _anchors.issue(
      anchor: anchor,
      localSigningKey: localSigningKey,
    );

    final fingerprint = await _anchors.fingerprint(anchor);

    await _anchors.verifyPinned(
      signed: signed,
      expectedUserUid: anchor.userUid,
      expectedDeviceId: anchor.deviceId,
      pinnedFingerprint: fingerprint,
    );

    final record = jsonEncode({
      'version': 1,
      'deviceId': anchor.deviceId,
      'fingerprint': fingerprint,
    });

    await _storage.write(key: key, value: record);

    return fingerprint;
  }

  Future<AndroidPinnedFirstDeviceRoot?> readPin({required String uid}) async {
    _requireAndroid();

    final raw = await _storage.read(key: _keyName(uid));

    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['deviceId'] is! String ||
          decoded['fingerprint'] is! String) {
        throw const FormatException('Invalid trust pin record.');
      }

      final deviceId = decoded['deviceId'] as String;
      final fingerprint = decoded['fingerprint'] as String;

      if (deviceId.trim().isEmpty ||
          deviceId.length > 128 ||
          deviceId.codeUnits.any((value) => value < 32) ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(fingerprint)) {
        throw const FormatException('Invalid trust pin contents.');
      }

      return AndroidPinnedFirstDeviceRoot(
        deviceId: deviceId,
        fingerprint: fingerprint,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Unreadable first-device trust pin.');
    }
  }
}

class AndroidPinnedFirstDeviceRoot {
  const AndroidPinnedFirstDeviceRoot({
    required this.deviceId,
    required this.fingerprint,
  });

  final String deviceId;
  final String fingerprint;
}
