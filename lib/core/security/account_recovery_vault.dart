import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Experimental encrypted backup of a portable account data key.
///
/// This does NOT back up device private keys, authorize new devices,
/// or restore access to revoked trips.
class AccountRecoveryEnvelope {
  const AccountRecoveryEnvelope({
    required this.userUid,
    required this.rootFingerprint,
    required this.revision,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  static const version = 1;
  static const algorithm = 'HKDF-SHA256-AES256-GCM';

  final String userUid;
  final String rootFingerprint;
  final int revision;
  final String salt;
  final String nonce;
  final String ciphertext;
  final String mac;

  Map<String, dynamic> toMap() => {
    'version': version,
    'algorithm': algorithm,
    'userUid': userUid,
    'rootFingerprint': rootFingerprint,
    'revision': revision,
    'salt': salt,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'mac': mac,
  };

  factory AccountRecoveryEnvelope.fromMap(Map<String, dynamic> map) {
    const fields = {
      'version',
      'algorithm',
      'userUid',
      'rootFingerprint',
      'revision',
      'salt',
      'nonce',
      'ciphertext',
      'mac',
    };

    if (map.keys.toSet().difference(fields).isNotEmpty ||
        map.length != fields.length ||
        map['version'] != version ||
        map['algorithm'] != algorithm ||
        map['userUid'] is! String ||
        map['rootFingerprint'] is! String ||
        map['revision'] is! int ||
        map['salt'] is! String ||
        map['nonce'] is! String ||
        map['ciphertext'] is! String ||
        map['mac'] is! String) {
      throw const FormatException('Invalid account recovery envelope.');
    }

    return AccountRecoveryEnvelope(
      userUid: map['userUid'] as String,
      rootFingerprint: map['rootFingerprint'] as String,
      revision: map['revision'] as int,
      salt: map['salt'] as String,
      nonce: map['nonce'] as String,
      ciphertext: map['ciphertext'] as String,
      mac: map['mac'] as String,
    );
  }
}

class AccountRecoveryVault {
  final AesGcm _aes = AesGcm.with256bits();

  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Generates 256-bit cryptographically random local material.
  ///
  /// A real recovery secret must be shown securely to the account
  /// owner and NEVER uploaded, logged, or sent to analytics.
  Future<List<int>> generateLocalSecret() async {
    final key = await _aes.newSecretKey();
    return List<int>.unmodifiable(await key.extractBytes());
  }

  Future<AccountRecoveryEnvelope> seal({
    required List<int> recoverySecret,
    required List<int> portableDataKey,
    required String userUid,
    required String rootFingerprint,
    required int revision,
  }) async {
    _checkKey(recoverySecret);
    _checkKey(portableDataKey);
    _checkContext(userUid, rootFingerprint, revision);

    final context = _context(userUid, rootFingerprint, revision);
    final salt = await generateLocalSecret();

    final wrappingKey = await _derive(recoverySecret, salt, context);

    final box = await _aes.encrypt(
      portableDataKey,
      secretKey: wrappingKey,
      nonce: _aes.newNonce(),
      aad: context,
    );

    return AccountRecoveryEnvelope(
      userUid: userUid,
      rootFingerprint: rootFingerprint,
      revision: revision,
      salt: base64Encode(salt),
      nonce: base64Encode(box.nonce),
      ciphertext: base64Encode(box.cipherText),
      mac: base64Encode(box.mac.bytes),
    );
  }

  Future<List<int>> open({
    required AccountRecoveryEnvelope envelope,
    required List<int> recoverySecret,
    required String expectedUserUid,
    required String expectedRootFingerprint,
    required int expectedRevision,
  }) async {
    _checkKey(recoverySecret);

    _checkContext(expectedUserUid, expectedRootFingerprint, expectedRevision);

    _checkContext(
      envelope.userUid,
      envelope.rootFingerprint,
      envelope.revision,
    );

    if (envelope.userUid != expectedUserUid ||
        envelope.rootFingerprint != expectedRootFingerprint ||
        envelope.revision != expectedRevision) {
      throw StateError('Recovery identity context mismatch.');
    }

    final salt = base64Decode(envelope.salt);
    final nonce = base64Decode(envelope.nonce);
    final ciphertext = base64Decode(envelope.ciphertext);
    final mac = base64Decode(envelope.mac);

    if (salt.length != 32 ||
        nonce.length != _aes.nonceLength ||
        ciphertext.length != 32 ||
        mac.length != _aes.macAlgorithm.macLength) {
      throw const FormatException('Invalid recovery envelope lengths.');
    }

    final context = _context(
      expectedUserUid,
      expectedRootFingerprint,
      expectedRevision,
    );

    final wrappingKey = await _derive(recoverySecret, salt, context);

    final plaintext = await _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
      secretKey: wrappingKey,
      aad: context,
    );

    _checkKey(plaintext);
    return List<int>.unmodifiable(plaintext);
  }

  Future<SecretKey> _derive(
    List<int> recoverySecret,
    List<int> salt,
    List<int> context,
  ) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(recoverySecret),
      nonce: salt,
      info: context,
    );
  }

  List<int> _context(String uid, String fingerprint, int revision) {
    return utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'account-recovery-vault',
        AccountRecoveryEnvelope.version,
        uid,
        fingerprint,
        revision,
      ]),
    );
  }

  void _checkContext(String uid, String fingerprint, int revision) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((value) => value < 32) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(fingerprint) ||
        revision <= 0) {
      throw ArgumentError('Invalid recovery identity context.');
    }
  }

  void _checkKey(List<int> key) {
    if (key.length != 32 || key.any((value) => value < 0 || value > 255)) {
      throw ArgumentError('Expected exactly 32 valid key bytes.');
    }
  }
}
