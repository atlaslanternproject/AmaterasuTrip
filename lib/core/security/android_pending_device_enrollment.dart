import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'android_device_key_storage.dart';
import 'android_device_signing_key_storage.dart';
import 'device_enrollment_request.dart';
import 'persistent_device_enrollment_request.dart';

/// Prepares a real Android device identity for E2EE enrollment.
///
/// Creating an identity does NOT approve the device.
/// Approval or independently verified recovery is still mandatory.
final class AndroidPendingDeviceEnrollment {
  AndroidPendingDeviceEnrollment({
    FlutterSecureStorage? storage,
    AndroidDeviceKeyStorage? exchangeKeys,
    AndroidDeviceSigningKeyStorage? signingKeys,
  }) : _storage =
           storage ??
           FlutterSecureStorage(
             aOptions: const AndroidOptions(
               storageNamespace: 'amaterasu_health_keys_v1',
               resetOnError: false,
             ),
           ),
       _exchangeKeys = exchangeKeys ?? AndroidDeviceKeyStorage(),
       _signingKeys = signingKeys ?? AndroidDeviceSigningKeyStorage();

  final FlutterSecureStorage _storage;
  final AndroidDeviceKeyStorage _exchangeKeys;
  final AndroidDeviceSigningKeyStorage _signingKeys;

  void _validateUser(String uid) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Android E2EE enrollment requires Android.');
    }

    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.trim() != uid ||
        uid.codeUnits.any((value) => value < 32)) {
      throw ArgumentError('Invalid E2EE user identity.');
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != uid || !user.emailVerified) {
      throw StateError('A verified authenticated account is required.');
    }
  }

  String _metadataKey(String uid) =>
      'pending_e2ee_identity_v1_${base64UrlEncode(utf8.encode(uid))}';

  /// Explicit user action only.
  ///
  /// Private keys are created locally. They are never exported
  /// to Firebase, cloud functions, analytics or logs.
  ///
  /// An interrupted partial creation requires recovery.
  /// It must not silently replace an existing identity.
  Future<DeviceEnrollmentRequest> prepareApprovalRequest({
    required String uid,
    required bool userConfirmed,
  }) async {
    _validateUser(uid);

    if (!userConfirmed) {
      throw StateError('Explicit device enrollment consent is required.');
    }

    final key = _metadataKey(uid);
    var raw = await _storage.read(key: key);

    if (raw == null) {
      if (await _exchangeKeys.readPrivateKey(uid: uid) != null) {
        throw StateError('Device identity is incomplete; recovery required.');
      }

      final randomId = await AesGcm.with256bits().newSecretKey();
      final deviceId = base64UrlEncode(
        await randomId.extractBytes(),
      ).replaceAll('=', '');

      final exchange = await X25519().newKeyPair();
      final signer = await Ed25519().newKeyPair();

      final exchangePublic = await exchange.extractPublicKey();
      final signingPublic = await signer.extractPublicKey();
      final exchangePrivate = await exchange.extractPrivateKeyBytes();

      await _exchangeKeys.savePrivateKey(
        uid: uid,
        privateKeyBytes: exchangePrivate,
      );

      await _signingKeys.saveSigningKey(
        uid: uid,
        deviceId: deviceId,
        keyPair: signer,
      );

      raw = jsonEncode({
        'version': 1,
        'uid': uid,
        'deviceId': deviceId,
        'x25519Public': base64Encode(exchangePublic.bytes),
        'ed25519Public': base64Encode(signingPublic.bytes),
        'state': 'pending_approval',
      });

      // Metadata is written only after both private keys.
      await _storage.write(key: key, value: raw);
    }

    final record = _decode(raw, uid);

    await _verifyStoredPrivateKeys(uid, record);

    // Reuse the original pending challenge until it expires.
    // Approval and membership verification remain separate.
    return PersistentDeviceEnrollmentRequest(
      read: (key) => _storage.read(key: key),
      write: (key, value) => _storage.write(key: key, value: value),
    ).obtain(
      uid: uid,
      deviceId: record.deviceId,
      x25519PublicKey: record.x25519Public,
      ed25519PublicKey: record.ed25519Public,
      nowUtc: DateTime.now().toUtc(),
    );
  }

  /// Reads an existing, unexpired approval request.
  ///
  /// Read-only: does not generate keys, establish trust or
  /// approve the device.
  Future<DeviceEnrollmentRequest?> readSavedApprovalRequest({
    required String uid,
  }) async {
    _validateUser(uid);

    final identityRaw = await _storage.read(key: _metadataKey(uid));

    if (identityRaw == null) {
      return null;
    }

    final identity = _decode(identityRaw, uid);

    final requestKey =
        'pending_enrollment_request_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';

    final savedRaw = await _storage.read(key: requestKey);

    if (savedRaw == null) {
      return null;
    }

    late final Map<String, dynamic> saved;

    try {
      final parsed = jsonDecode(savedRaw);

      if (parsed is! Map<String, dynamic> ||
          parsed.length != 3 ||
          parsed['version'] != 1 ||
          parsed['payload'] is! String ||
          parsed['expiresAtMs'] is! int) {
        throw const FormatException('Invalid saved enrollment request.');
      }

      saved = parsed;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Corrupt saved enrollment request.');
    }

    final now = DateTime.now().toUtc();
    final expiry = saved['expiresAtMs'] as int;

    if (expiry <= 0) {
      throw const FormatException('Invalid saved enrollment expiration.');
    }

    if (now.millisecondsSinceEpoch >= expiry) {
      // Expired requests are never returned.
      // Renewal requires explicit user confirmation.
      return null;
    }

    // A valid request must still match locally stored private keys.
    // Expired requests are rejected before expensive verification.
    await _verifyStoredPrivateKeys(uid, identity);
    final request = DeviceEnrollmentRequest.fromQrPayload(
      saved['payload'] as String,
      expectedUserUid: uid,
      nowUtc: now,
    );

    if (request.toQrPayload() != saved['payload'] ||
        request.expiresAtMs != expiry ||
        request.newDeviceId != identity.deviceId ||
        !_same(request.x25519PublicKey, identity.x25519Public) ||
        !_same(request.ed25519PublicKey, identity.ed25519Public)) {
      throw const FormatException('Saved enrollment identity mismatch.');
    }

    return request;
  }

  /// Read-only UI status. Never authorises or replaces a device.
  Future<bool> hasExpiredSavedRequest({required String uid}) async {
    _validateUser(uid);

    final key =
        'pending_enrollment_request_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';

    final raw = await _storage.read(key: key);

    if (raw == null) return false;

    try {
      final data = jsonDecode(raw);

      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['expiresAtMs'] is! int ||
          data['payload'] is! String) {
        return false;
      }

      return DateTime.now().toUtc().millisecondsSinceEpoch >=
          (data['expiresAtMs'] as int);
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifyStoredPrivateKeys(
    String uid,
    _PendingRecord record,
  ) async {
    final privateBytes = await _exchangeKeys.readPrivateKey(uid: uid);

    final signer = await _signingKeys.readSigningKey(
      uid: uid,
      deviceId: record.deviceId,
    );

    if (privateBytes == null || signer == null) {
      throw StateError('Device identity keys are missing; recovery required.');
    }

    final signerPublic = await signer.extractPublicKey();

    if (!_same(signerPublic.bytes, record.ed25519Public)) {
      throw const FormatException('Invalid local signing identity.');
    }

    // Check that the stored X25519 public key actually corresponds
    // to the locally stored private key.
    final algorithm = X25519();

    final local = SimpleKeyPairData(
      privateBytes,
      publicKey: SimplePublicKey(record.x25519Public, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );

    final challengePair = await algorithm.newKeyPair();
    final challengePublic = await challengePair.extractPublicKey();

    final actual = await algorithm.sharedSecretKey(
      keyPair: local,
      remotePublicKey: challengePublic,
    );

    final expected = await algorithm.sharedSecretKey(
      keyPair: challengePair,
      remotePublicKey: await local.extractPublicKey(),
    );

    if (!_same(await actual.extractBytes(), await expected.extractBytes())) {
      throw const FormatException('Invalid local X25519 identity.');
    }
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;

    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }

  _PendingRecord _decode(String raw, String expectedUid) {
    try {
      final data = jsonDecode(raw);

      if (data is! Map<String, dynamic> ||
          data.length != 6 ||
          data['version'] != 1 ||
          data['uid'] != expectedUid ||
          data['deviceId'] is! String ||
          data['x25519Public'] is! String ||
          data['ed25519Public'] is! String ||
          data['state'] != 'pending_approval') {
        throw const FormatException('Invalid pending device identity.');
      }

      final deviceId = data['deviceId'] as String;
      final xPublic = base64Decode(data['x25519Public'] as String);
      final edPublic = base64Decode(data['ed25519Public'] as String);

      if (deviceId.length != 43 ||
          xPublic.length != 32 ||
          edPublic.length != 32) {
        throw const FormatException('Invalid pending device identity fields.');
      }

      return _PendingRecord(deviceId, xPublic, edPublic);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Corrupt pending device identity.');
    }
  }
}

final class _PendingRecord {
  const _PendingRecord(this.deviceId, this.x25519Public, this.ed25519Public);

  final String deviceId;
  final List<int> x25519Public;
  final List<int> ed25519Public;
}
