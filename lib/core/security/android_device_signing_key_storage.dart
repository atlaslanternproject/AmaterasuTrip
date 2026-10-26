import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores Ed25519 signing identity material on Android.
///
/// The private key is protected at rest by flutter_secure_storage,
/// but is extractable into Dart memory when used.
///
/// This is not a hardware-non-exportable Ed25519 implementation.
class AndroidDeviceSigningKeyStorage {
  AndroidDeviceSigningKeyStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(
              storageNamespace: 'amaterasu_health_keys_v1',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;
  final Ed25519 _algorithm = Ed25519();

  void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Android signing storage required.');
    }
  }

  String _keyName(String uid, String deviceId) {
    for (final id in [uid, deviceId]) {
      if (id.trim().isEmpty ||
          id.length > 128 ||
          id.codeUnits.any((value) => value < 32)) {
        throw ArgumentError('Invalid identity identifier.');
      }
    }

    final userPart = base64UrlEncode(utf8.encode(uid));
    final devicePart = base64UrlEncode(utf8.encode(deviceId));

    return 'ed25519_signing_private_v1:$userPart:$devicePart';
  }

  Future<SimpleKeyPairData> _restore({
    required List<int> privateBytes,
    required List<int> publicBytes,
  }) async {
    if (privateBytes.length != 32 || publicBytes.length != 32) {
      throw const FormatException('Invalid Ed25519 key length.');
    }

    final publicKey = SimplePublicKey(publicBytes, type: KeyPairType.ed25519);

    final pair = SimpleKeyPairData(
      privateBytes,
      publicKey: publicKey,
      type: KeyPairType.ed25519,
    );

    // Reject a mismatched private/public key combination.
    final message = utf8.encode('amaterasutrip-ed25519-identity-integrity-v1');

    final signature = await _algorithm.sign(message, keyPair: pair);

    final valid = await _algorithm.verify(
      message,
      signature: Signature(signature.bytes, publicKey: publicKey),
    );

    if (!valid) {
      pair.destroy();
      throw const FormatException('Inconsistent Ed25519 key pair.');
    }

    return pair;
  }

  Future<void> saveSigningKey({
    required String uid,
    required String deviceId,
    required SimpleKeyPair keyPair,
  }) async {
    _requireAndroid();

    final key = _keyName(uid, deviceId);
    final existing = await _storage.read(key: key);

    if (existing != null) {
      throw StateError('Device signing identity already exists.');
    }

    final publicKey = await keyPair.extractPublicKey();
    if (publicKey.type != KeyPairType.ed25519) {
      throw ArgumentError('Expected Ed25519 signing key.');
    }

    final privateBytes = await keyPair.extractPrivateKeyBytes();

    final checked = await _restore(
      privateBytes: privateBytes,
      publicBytes: publicKey.bytes,
    );
    checked.destroy();

    final value = jsonEncode({
      'version': 1,
      'algorithm': 'Ed25519',
      'private': base64Encode(privateBytes),
      'public': base64Encode(publicKey.bytes),
    });

    await _storage.write(key: key, value: value);
  }

  Future<SimpleKeyPairData?> readSigningKey({
    required String uid,
    required String deviceId,
  }) async {
    _requireAndroid();

    final raw = await _storage.read(key: _keyName(uid, deviceId));

    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['algorithm'] != 'Ed25519' ||
          decoded['private'] is! String ||
          decoded['public'] is! String) {
        throw const FormatException('Invalid signing key format.');
      }

      return await _restore(
        privateBytes: base64Decode(decoded['private'] as String),
        publicBytes: base64Decode(decoded['public'] as String),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid stored signing identity.');
    }
  }

  Future<void> deleteSigningKey({
    required String uid,
    required String deviceId,
  }) async {
    _requireAndroid();

    await _storage.delete(key: _keyName(uid, deviceId));
  }
}
