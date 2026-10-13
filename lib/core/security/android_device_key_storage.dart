import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android-only storage for a device X25519 private key.
///
/// This component does not generate keys or communicate with Firebase.
/// It must not be used until Android backup exclusions are configured.
class AndroidDeviceKeyStorage {
  AndroidDeviceKeyStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(
              storageNamespace: 'amaterasu_health_keys_v1',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;

  static const int privateKeyLength = 32;

  void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Android device key storage is not available on this platform.',
      );
    }
  }

  String _keyName(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError('A valid user UID is required.');
    }

    final encodedUid = base64UrlEncode(utf8.encode(uid));

    return 'x25519_private_v1_$encodedUid';
  }

  Future<void> savePrivateKey({
    required String uid,
    required List<int> privateKeyBytes,
  }) async {
    _requireAndroid();

    if (privateKeyBytes.length != privateKeyLength ||
        privateKeyBytes.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError('Invalid X25519 private key representation.');
    }

    final key = _keyName(uid);

    final existing = await _storage.read(key: key);

    if (existing != null) {
      throw StateError(
        'A private key already exists for this user on this device.',
      );
    }

    await _storage.write(key: key, value: base64Encode(privateKeyBytes));
  }

  Future<List<int>?> readPrivateKey({required String uid}) async {
    _requireAndroid();

    final encoded = await _storage.read(key: _keyName(uid));

    if (encoded == null) {
      return null;
    }

    final bytes = base64Decode(encoded);

    if (bytes.length != privateKeyLength) {
      throw const FormatException('Invalid stored private key length.');
    }

    return bytes;
  }

  Future<void> deletePrivateKey({required String uid}) async {
    _requireAndroid();

    await _storage.delete(key: _keyName(uid));
  }
}
