import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Root identity material. Private bytes NEVER go to Firestore in clear.
final class FirstRootLocalIdentity {
  const FirstRootLocalIdentity({
    required this.uid,
    required this.deviceId,
    required this.createdAtMs,
    required this.exchangePrivate,
    required this.exchangePublic,
    required this.signingPrivate,
    required this.signingPublic,
  });

  final String uid;
  final String deviceId;
  final int createdAtMs;
  final List<int> exchangePrivate;
  final List<int> exchangePublic;
  final List<int> signingPrivate;
  final List<int> signingPublic;

  SimpleKeyPair get signingKey => SimpleKeyPairData(
    signingPrivate,
    publicKey: SimplePublicKey(signingPublic, type: KeyPairType.ed25519),
    type: KeyPairType.ed25519,
  );
}

/// Storage remains local to the browser/original Android installation.
/// Web secure storage is experimental and is NOT resistant to XSS.
final class FirstRootLocalIdentityStorage {
  FirstRootLocalIdentityStorage()
    : _storage = FlutterSecureStorage(
        aOptions: const AndroidOptions(
          storageNamespace: 'amaterasu_health_keys_v1',
          resetOnError: false,
        ),
      );

  final FlutterSecureStorage _storage;

  String _key(String uid) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((v) => v < 32)) {
      throw ArgumentError('Invalid account identifier.');
    }
    return 'first_root_private_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';
  }

  Future<FirstRootLocalIdentity?> read(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);

      if (json is! Map<String, dynamic> ||
          json['version'] != 1 ||
          json['uid'] != uid ||
          json['deviceId'] is! String ||
          json['createdAtMs'] is! int) {
        throw const FormatException('Invalid local root identity.');
      }

      List<int> bytes(String name) {
        final value = json[name];
        if (value is! String) {
          throw const FormatException('Missing identity material.');
        }
        final decoded = base64Decode(value);
        if (decoded.length != 32) {
          throw const FormatException('Invalid identity key length.');
        }
        return decoded;
      }

      final identity = FirstRootLocalIdentity(
        uid: uid,
        deviceId: json['deviceId'] as String,
        createdAtMs: json['createdAtMs'] as int,
        exchangePrivate: bytes('xPrivate'),
        exchangePublic: bytes('xPublic'),
        signingPrivate: bytes('edPrivate'),
        signingPublic: bytes('edPublic'),
      );

      if (identity.deviceId.length != 43 || identity.createdAtMs <= 0) {
        throw const FormatException('Invalid identity metadata.');
      }

      // Verify that the persisted signing key matches its public key.
      final challenge = utf8.encode('amaterasutrip-local-root-integrity-v1');
      final signature = await Ed25519().sign(
        challenge,
        keyPair: identity.signingKey,
      );
      final signatureValid = await Ed25519().verify(
        challenge,
        signature: Signature(
          signature.bytes,
          publicKey: SimplePublicKey(
            identity.signingPublic,
            type: KeyPairType.ed25519,
          ),
        ),
      );
      if (!signatureValid) {
        throw const FormatException('Local signing key mismatch.');
      }

      // Also prove the X25519 private/public key correspondence.
      final x = X25519();
      final local = SimpleKeyPairData(
        identity.exchangePrivate,
        publicKey: SimplePublicKey(
          identity.exchangePublic,
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );
      final test = await x.newKeyPair();
      final testPublic = await test.extractPublicKey();
      final actual = await x.sharedSecretKey(
        keyPair: local,
        remotePublicKey: testPublic,
      );
      final expected = await x.sharedSecretKey(
        keyPair: test,
        remotePublicKey: await local.extractPublicKey(),
      );
      final a = await actual.extractBytes();
      final b = await expected.extractBytes();

      var difference = 0;
      for (var i = 0; i < 32; i++) {
        difference |= a[i] ^ b[i];
      }
      if (difference != 0) {
        throw const FormatException('Local exchange key mismatch.');
      }

      return identity;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Unreadable local root identity.');
    }
  }

  Future<FirstRootLocalIdentity> prepare(String uid) async {
    final existing = await read(uid);
    if (existing != null) return existing;

    final exchange = await X25519().newKeyPair();
    final signer = await Ed25519().newKeyPair();
    final random = await AesGcm.with256bits().newSecretKey();

    final identity = FirstRootLocalIdentity(
      uid: uid,
      deviceId: base64UrlEncode(
        await random.extractBytes(),
      ).replaceAll('=', ''),
      createdAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      exchangePrivate: await exchange.extractPrivateKeyBytes(),
      exchangePublic: (await exchange.extractPublicKey()).bytes,
      signingPrivate: await signer.extractPrivateKeyBytes(),
      signingPublic: (await signer.extractPublicKey()).bytes,
    );

    final value = jsonEncode({
      'version': 1,
      'uid': uid,
      'deviceId': identity.deviceId,
      'createdAtMs': identity.createdAtMs,
      'xPrivate': base64Encode(identity.exchangePrivate),
      'xPublic': base64Encode(identity.exchangePublic),
      'edPrivate': base64Encode(identity.signingPrivate),
      'edPublic': base64Encode(identity.signingPublic),
    });

    // Never silently overwrite pre-existing local identity material.
    if (await _storage.read(key: _key(uid)) != null) {
      throw StateError('Root identity already exists.');
    }

    await _storage.write(key: _key(uid), value: value);

    return (await read(uid))!;
  }
}
