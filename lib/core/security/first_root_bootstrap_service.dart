import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'account_recovery_kit.dart';
import 'account_recovery_vault.dart';
import 'android_first_device_trust_pin_storage.dart';
import 'first_device_trust_anchor.dart';
import 'first_root_local_identity.dart';
import 'first_device_bootstrap_policy.dart';
import 'first_root_registration_provenance.dart';
import 'first_root_server_registration.dart';

import 'first_root_pin_stub.dart'
    if (dart.library.io) 'first_root_pin_io.dart'
    if (dart.library.js_interop) 'first_root_pin_web.dart'
    as local_pin;

enum FirstRootState {
  setupAvailable,
  activeOnThisDevice,
  approvalOrRecoveryRequired,
  blocked,
  verificationRequired,
}

final class PreparedFirstRoot {
  const PreparedFirstRoot({
    required this.uid,
    required this.signed,
    required this.fingerprint,
    required this.recoveryCode,
    required this.encryptedRecovery,
  });

  final String uid;
  final SignedFirstDeviceTrustAnchor signed;
  final String fingerprint;
  final String recoveryCode;
  final Map<String, dynamic> encryptedRecovery;
}

/// First-root registration only. This service does NOT grant trip
/// memberships, decrypt health records or approve later devices.
final class FirstRootBootstrapService {
  final _anchors = FirstDeviceTrustAnchorService();
  final _local = FirstRootLocalIdentityStorage();
  final _db = FirebaseFirestore.instance;
  final _policy = const FirstDeviceBootstrapPolicy();
  final _provenance = FirstRootRegistrationProvenance();

  User _user() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('Verified sign-in required.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _db.collection('e2eeRoots').doc(uid);

  Future<Map<String, dynamic>?> _remote(String uid) async {
    // Never infer root absence from an offline Firestore cache.
    final snapshot = await _document(
      uid,
    ).get(const GetOptions(source: Source.server));
    return snapshot.data();
  }

  SignedFirstDeviceTrustAnchor _decode(
    Map<String, dynamic> record,
    String uid,
  ) {
    if (record['version'] != 1 ||
        record['userUid'] != uid ||
        record['deviceId'] is! String ||
        record['createdAtMs'] is! int ||
        record['x25519PublicKey'] is! String ||
        record['ed25519PublicKey'] is! String ||
        record['signature'] is! String ||
        record['fingerprint'] is! String) {
      throw const FormatException('Invalid first-root record.');
    }

    final anchor = FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: record['deviceId'] as String,
      createdAtMs: record['createdAtMs'] as int,
      x25519PublicKey: base64Decode(record['x25519PublicKey'] as String),
      ed25519PublicKey: base64Decode(record['ed25519PublicKey'] as String),
    );

    return SignedFirstDeviceTrustAnchor(
      anchor: anchor,
      signatureBytes: base64Decode(record['signature'] as String),
    );
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  Future<FirstRootState> inspect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return FirstRootState.verificationRequired;
    }

    final uid = user.uid;

    // Storage failures and network errors propagate: never pretend
    // that an unavailable root is an absent root.
    final remote = await _remote(uid);
    final pin = await local_pin.readRootPin(uid);

    if (remote == null) {
      if (pin != null) {
        // A previously pinned identity must never be replaced.
        return FirstRootState.blocked;
      }

      // Registration provenance is a client-side flow hint only.
      // A missing Firestore root is NOT sufficient authorisation.
      final entry = await _provenance.entryFor(user);

      final decision = _policy.evaluate(
        authenticated: true,
        emailVerified: user.emailVerified,
        userExplicitlyRequestedSetup: true,
        entry: entry,
        local: LocalSecurityIdentity.absent,
        remote: RemoteSecurityIdentity.missing,
      );

      return decision == ProtectedIdentityAction.proposeFirstDeviceSetup
          ? FirstRootState.setupAvailable
          : FirstRootState.approvalOrRecoveryRequired;
    }

    if (pin == null) {
      return FirstRootState.approvalOrRecoveryRequired;
    }

    try {
      final signed = _decode(remote, uid);
      final claimedFingerprint = remote['fingerprint'];

      if (claimedFingerprint != pin.fingerprint ||
          pin.deviceId != signed.anchor.deviceId) {
        return FirstRootState.blocked;
      }

      await _anchors.verifyPinned(
        signed: signed,
        expectedUserUid: uid,
        expectedDeviceId: pin.deviceId,
        pinnedFingerprint: pin.fingerprint,
      );

      final localIdentity = await _local.read(uid);
      if (localIdentity == null) {
        return FirstRootState.approvalOrRecoveryRequired;
      }

      if (localIdentity.deviceId != signed.anchor.deviceId ||
          !_same(localIdentity.exchangePublic, signed.anchor.x25519PublicKey) ||
          !_same(localIdentity.signingPublic, signed.anchor.ed25519PublicKey)) {
        return FirstRootState.blocked;
      }

      return FirstRootState.activeOnThisDevice;
    } catch (_) {
      return FirstRootState.blocked;
    }
  }

  Future<void> _requireRecentSignIn(User user) async {
    final token = await user.getIdTokenResult(true);
    final authTime = token.authTime;

    if (authTime == null ||
        DateTime.now().toUtc().difference(authTime.toUtc()).abs() >
            const Duration(minutes: 5)) {
      throw StateError('Recent sign-in required. Sign out and sign in again.');
    }
  }

  Future<PreparedFirstRoot> prepare() async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Android or Web required.');
    }

    final user = _user();

    if (await _provenance.entryFor(user) !=
        SecurityAccountEntry.createdInCurrentRegistration) {
      throw StateError('Independent first-root eligibility required.');
    }

    await _requireRecentSignIn(user);

    if (await inspect() != FirstRootState.setupAvailable) {
      throw StateError('An identity already exists or is unavailable.');
    }

    final identity = await _local.prepare(user.uid);

    final anchor = FirstDeviceTrustAnchor(
      userUid: user.uid,
      deviceId: identity.deviceId,
      x25519PublicKey: identity.exchangePublic,
      ed25519PublicKey: identity.signingPublic,
      createdAtMs: identity.createdAtMs,
    );

    final signed = await _anchors.issue(
      anchor: anchor,
      localSigningKey: identity.signingKey,
    );

    final fingerprint = await _anchors.fingerprint(anchor);

    await _anchors.verifyPinned(
      signed: signed,
      expectedUserUid: user.uid,
      expectedDeviceId: identity.deviceId,
      pinnedFingerprint: fingerprint,
    );

    // The recovery secret stays exclusively with the user.
    // Only authenticated ciphertext is included in Firestore.
    final secret = await AccountRecoveryVault().generateLocalSecret();

    final recoveryCode = await AccountRecoveryKitCodec().encode(
      userUid: user.uid,
      rootFingerprint: fingerprint,
      recoverySecret: secret,
    );

    final aes = AesGcm.with256bits();
    final salt = await aes.newSecretKey();
    final saltBytes = await salt.extractBytes();

    final context = utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'first-root-private-backup',
        1,
        user.uid,
        fingerprint,
      ]),
    );

    final wrappingKey = await Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(secretKey: SecretKey(secret), nonce: saltBytes, info: context);

    final plaintext = [...identity.exchangePrivate, ...identity.signingPrivate];

    final encrypted = await aes.encrypt(
      plaintext,
      secretKey: wrappingKey,
      nonce: aes.newNonce(),
      aad: context,
    );

    return PreparedFirstRoot(
      uid: user.uid,
      signed: signed,
      fingerprint: fingerprint,
      recoveryCode: recoveryCode,
      encryptedRecovery: {
        'version': 1,
        'salt': base64Encode(saltBytes),
        'nonce': base64Encode(encrypted.nonce),
        'ciphertext': base64Encode(encrypted.cipherText),
        'mac': base64Encode(encrypted.mac.bytes),
      },
    );
  }

  Future<void> activate(PreparedFirstRoot prepared) async {
    final user = _user();

    if (user.uid != prepared.uid) {
      throw StateError('Account changed during activation.');
    }

    if (await _provenance.entryFor(user) !=
        SecurityAccountEntry.createdInCurrentRegistration) {
      throw StateError('Independent first-root eligibility required.');
    }

    await _requireRecentSignIn(user);

    if (await inspect() != FirstRootState.setupAvailable) {
      throw StateError('First-root registration is no longer allowed.');
    }

    final localIdentity = await _local.read(user.uid);

    if (localIdentity == null ||
        localIdentity.deviceId != prepared.signed.anchor.deviceId ||
        !_same(
          localIdentity.signingPublic,
          prepared.signed.anchor.ed25519PublicKey,
        ) ||
        !_same(
          localIdentity.exchangePublic,
          prepared.signed.anchor.x25519PublicKey,
        )) {
      throw StateError('Local root identity changed.');
    }

    await _anchors.verifyPinned(
      signed: prepared.signed,
      expectedUserUid: user.uid,
      expectedDeviceId: localIdentity.deviceId,
      pinnedFingerprint: prepared.fingerprint,
    );

    final anchor = prepared.signed.anchor;

    final data = <String, dynamic>{
      'version': 1,
      'userUid': user.uid,
      'deviceId': anchor.deviceId,
      'createdAtMs': anchor.createdAtMs,
      'x25519PublicKey': base64Encode(anchor.x25519PublicKey),
      'ed25519PublicKey': base64Encode(anchor.ed25519PublicKey),
      'signature': base64Encode(prepared.signed.signatureBytes),
      'fingerprint': prepared.fingerprint,
      'recovery': prepared.encryptedRecovery,
    };

    // The signed first root must be registered by the server.
    // Lost responses require a full server record verification.
    try {
      await FirstRootServerRegistration().register(
        root: data,
        expectedDeviceId: anchor.deviceId,
        expectedFingerprint: prepared.fingerprint,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!FirstRootServerRegistration.mayHaveCommitted(error.code)) {
        rethrow;
      }
    }

    // Do not trust an unacknowledged/local pending write.
    final committed = await _remote(user.uid);
    if (committed == null ||
        !FirstRootServerRegistration.matchesServerRecord(
          expected: data,
          actual: committed,
        )) {
      throw StateError('First-root server acknowledgement mismatch.');
    }

    await _anchors.verifyPinned(
      signed: _decode(committed, user.uid),
      expectedUserUid: user.uid,
      expectedDeviceId: anchor.deviceId,
      pinnedFingerprint: prepared.fingerprint,
    );

    // Only now persist the locally issued trust pin.
    if (kIsWeb) {
      await local_pin.pinRoot(prepared.signed);
    } else {
      await AndroidFirstDeviceTrustPinStorage().pinLocallyIssuedRoot(
        anchor: anchor,
        localSigningKey: localIdentity.signingKey,
      );
    }
  }
}
