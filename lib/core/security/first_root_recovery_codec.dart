import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'account_recovery_kit.dart';
import 'first_device_trust_anchor.dart';
import 'first_root_local_identity.dart';

/// Verifies a recovery code against the existing first-root backup.
///
/// Does not persist recovered keys, register a device or approve access.
final class FirstRootRecoveryCodec {
  final _aes = AesGcm.with256bits();
  final _anchors = FirstDeviceTrustAnchorService();

  Future<void> verify({
    required String recoveryCode,
    required String expectedUserUid,
    required SignedFirstDeviceTrustAnchor signed,
    required Map<String, dynamic> envelope,
  }) async {
    await recover(
      recoveryCode: recoveryCode,
      expectedUserUid: expectedUserUid,
      signed: signed,
      envelope: envelope,
    );
  }

  /// Returns verified key material without persisting it.
  /// Device enrollment and local storage are separate operations.
  Future<FirstRootLocalIdentity> recover({
    required String recoveryCode,
    required String expectedUserUid,
    required SignedFirstDeviceTrustAnchor signed,
    required Map<String, dynamic> envelope,
  }) async {
    final kit = await AccountRecoveryKitCodec().decode(recoveryCode);
    final anchor = signed.anchor;
    final fingerprint = await _anchors.fingerprint(anchor);

    if (kit.userUid != expectedUserUid ||
        anchor.userUid != expectedUserUid ||
        kit.rootFingerprint != fingerprint) {
      throw StateError('Recovery identity mismatch.');
    }

    await _anchors.verifyPinned(
      signed: signed,
      expectedUserUid: expectedUserUid,
      expectedDeviceId: anchor.deviceId,
      pinnedFingerprint: kit.rootFingerprint,
    );

    const requiredFields = {'version', 'salt', 'nonce', 'ciphertext', 'mac'};

    if (envelope.length != requiredFields.length ||
        !envelope.keys.toSet().containsAll(requiredFields) ||
        envelope['version'] != 1 ||
        envelope['salt'] is! String ||
        envelope['nonce'] is! String ||
        envelope['ciphertext'] is! String ||
        envelope['mac'] is! String) {
      throw const FormatException('Invalid recovery envelope.');
    }

    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    final ciphertext = base64Decode(envelope['ciphertext'] as String);
    final mac = base64Decode(envelope['mac'] as String);

    if (salt.length != 32 ||
        nonce.length != _aes.nonceLength ||
        ciphertext.length != 64 ||
        mac.length != _aes.macAlgorithm.macLength) {
      throw const FormatException('Invalid recovery envelope lengths.');
    }

    final context = utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'first-root-private-backup',
        1,
        expectedUserUid,
        kit.rootFingerprint,
      ]),
    );

    final wrappingKey = await Hkdf(hmac: Hmac.sha256(), outputLength: 32)
        .deriveKey(
          secretKey: SecretKey(kit.recoverySecret),
          nonce: salt,
          info: context,
        );

    final privateMaterial = await _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
      secretKey: wrappingKey,
      aad: context,
    );

    if (privateMaterial.length != 64) {
      throw const FormatException('Invalid recovered key material.');
    }

    final exchange = await X25519().newKeyPairFromSeed(
      privateMaterial.sublist(0, 32),
    );

    final signing = await Ed25519().newKeyPairFromSeed(
      privateMaterial.sublist(32, 64),
    );

    final exchangePublic = await exchange.extractPublicKey();
    final signingPublic = await signing.extractPublicKey();

    if (!_same(exchangePublic.bytes, anchor.x25519PublicKey) ||
        !_same(signingPublic.bytes, anchor.ed25519PublicKey)) {
      throw StateError('Recovered keys do not match signed root.');
    }

    return FirstRootLocalIdentity(
      uid: expectedUserUid,
      deviceId: anchor.deviceId,
      createdAtMs: anchor.createdAtMs,
      exchangePrivate: List<int>.unmodifiable(privateMaterial.sublist(0, 32)),
      exchangePublic: List<int>.unmodifiable(exchangePublic.bytes),
      signingPrivate: List<int>.unmodifiable(privateMaterial.sublist(32, 64)),
      signingPublic: List<int>.unmodifiable(signingPublic.bytes),
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
}
