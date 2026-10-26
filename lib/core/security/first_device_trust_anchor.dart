import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Public identity of the first device.
/// This is not trusted merely because it exists in Firestore.
class FirstDeviceTrustAnchor {
  FirstDeviceTrustAnchor({
    required this.userUid,
    required this.deviceId,
    required List<int> x25519PublicKey,
    required List<int> ed25519PublicKey,
    required this.createdAtMs,
  }) : x25519PublicKey = List<int>.unmodifiable(x25519PublicKey),
       ed25519PublicKey = List<int>.unmodifiable(ed25519PublicKey);

  final String userUid;
  final String deviceId;
  final List<int> x25519PublicKey;
  final List<int> ed25519PublicKey;
  final int createdAtMs;

  List<int> get signingBytes => utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'first-device-trust-anchor',
      1,
      userUid,
      deviceId,
      base64Encode(x25519PublicKey),
      base64Encode(ed25519PublicKey),
      createdAtMs,
    ]),
  );
}

class SignedFirstDeviceTrustAnchor {
  SignedFirstDeviceTrustAnchor({
    required this.anchor,
    required List<int> signatureBytes,
  }) : signatureBytes = List<int>.unmodifiable(signatureBytes);

  final FirstDeviceTrustAnchor anchor;
  final List<int> signatureBytes;
}

/// The fingerprint MUST originate from a locally generated identity
/// or a separately authenticated out-of-band verification.
///
/// Computing a fingerprint from a Firestore document and immediately
/// trusting that same fingerprint provides NO protection against
/// a backend that replaces both the document and its public key.
class FirstDeviceTrustAnchorService {
  final Ed25519 _signatures = Ed25519();
  final Sha256 _sha256 = Sha256();

  Future<String> fingerprint(FirstDeviceTrustAnchor anchor) async {
    _validate(anchor);

    final hash = await _sha256.hash(anchor.signingBytes);
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  /// Sign an initial identity using the corresponding local private key.
  Future<SignedFirstDeviceTrustAnchor> issue({
    required FirstDeviceTrustAnchor anchor,
    required SimpleKeyPair localSigningKey,
  }) async {
    _validate(anchor);

    final actualPublicKey = await localSigningKey.extractPublicKey();

    if (actualPublicKey.type != KeyPairType.ed25519 ||
        !_sameBytes(actualPublicKey.bytes, anchor.ed25519PublicKey)) {
      throw StateError('Local signing key does not match device identity.');
    }

    final signature = await _signatures.sign(
      anchor.signingBytes,
      keyPair: localSigningKey,
    );

    return SignedFirstDeviceTrustAnchor(
      anchor: anchor,
      signatureBytes: signature.bytes,
    );
  }

  /// Accept an identity ONLY against an independently trusted pin.
  Future<void> verifyPinned({
    required SignedFirstDeviceTrustAnchor signed,
    required String expectedUserUid,
    required String expectedDeviceId,
    required String pinnedFingerprint,
  }) async {
    final anchor = signed.anchor;
    _validate(anchor);

    if (anchor.userUid != expectedUserUid ||
        anchor.deviceId != expectedDeviceId) {
      throw StateError('First device identity context mismatch.');
    }

    final actualFingerprint = await fingerprint(anchor);

    if (pinnedFingerprint.isEmpty ||
        !_sameBytes(
          utf8.encode(actualFingerprint),
          utf8.encode(pinnedFingerprint),
        )) {
      throw StateError('First device identity fingerprint mismatch.');
    }

    if (signed.signatureBytes.length != 64) {
      throw StateError('Invalid first device signature length.');
    }

    final publicKey = SimplePublicKey(
      anchor.ed25519PublicKey,
      type: KeyPairType.ed25519,
    );

    final valid = await _signatures.verify(
      anchor.signingBytes,
      signature: Signature(signed.signatureBytes, publicKey: publicKey),
    );

    if (!valid) {
      throw StateError('First device identity signature invalid.');
    }
  }

  void _validate(FirstDeviceTrustAnchor anchor) {
    for (final identifier in [anchor.userUid, anchor.deviceId]) {
      if (identifier.trim().isEmpty ||
          identifier.length > 128 ||
          identifier.codeUnits.any((value) => value < 32)) {
        throw ArgumentError('Invalid first device identifier.');
      }
    }

    for (final key in [anchor.x25519PublicKey, anchor.ed25519PublicKey]) {
      if (key.length != 32 ||
          key.any((value) => value < 0 || value > 255) ||
          key.every((value) => value == 0)) {
        throw ArgumentError('Invalid first device public key.');
      }
    }

    if (anchor.createdAtMs <= 0) {
      throw ArgumentError('Invalid first device creation timestamp.');
    }
  }

  bool _sameBytes(List<int> first, List<int> second) {
    if (first.length != second.length) return false;

    var difference = 0;
    for (var i = 0; i < first.length; i++) {
      difference |= first[i] ^ second[i];
    }

    return difference == 0;
  }
}
