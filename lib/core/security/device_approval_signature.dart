import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// An approval request whose identity and key material must first
/// be compared via an authenticated out-of-band channel.
///
/// This is an experimental cryptographic building block, not a
/// complete device-enrolment or authorization protocol.
class DeviceApprovalClaim {
  DeviceApprovalClaim({
    required this.userUid,
    required this.approverDeviceId,
    required this.newDeviceId,
    required List<int> newX25519PublicKey,
    required List<int> newEd25519PublicKey,
    required List<int> challenge,
    required this.issuedAtMs,
    required this.expiresAtMs,
  }) : newX25519PublicKey = List<int>.unmodifiable(newX25519PublicKey),
       newEd25519PublicKey = List<int>.unmodifiable(newEd25519PublicKey),
       challenge = List<int>.unmodifiable(challenge);

  final String userUid;
  final String approverDeviceId;
  final String newDeviceId;

  final List<int> newX25519PublicKey;
  final List<int> newEd25519PublicKey;
  final List<int> challenge;

  final int issuedAtMs;
  final int expiresAtMs;

  List<int> get signingBytes => utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'device-approval',
      1,
      userUid,
      approverDeviceId,
      newDeviceId,
      base64Encode(newX25519PublicKey),
      base64Encode(newEd25519PublicKey),
      base64Encode(challenge),
      issuedAtMs,
      expiresAtMs,
    ]),
  );
}

class SignedDeviceApproval {
  SignedDeviceApproval({required this.claim, required List<int> signatureBytes})
    : signatureBytes = List<int>.unmodifiable(signatureBytes);

  final DeviceApprovalClaim claim;
  final List<int> signatureBytes;
}

/// The trusted signing key must come from a previously authenticated
/// trust anchor, NEVER solely from the untrusted approval document.
class DeviceApprovalSignatureService {
  final Ed25519 _ed25519 = Ed25519();

  static const int maximumLifetimeMs = 5 * 60 * 1000;
  static const int allowedClockSkewMs = 30 * 1000;

  Future<SignedDeviceApproval> sign({
    required DeviceApprovalClaim claim,
    required SimpleKeyPair trustedDeviceSigningKey,
  }) async {
    _validateClaim(claim);

    final signature = await _ed25519.sign(
      claim.signingBytes,
      keyPair: trustedDeviceSigningKey,
    );

    return SignedDeviceApproval(claim: claim, signatureBytes: signature.bytes);
  }

  Future<void> verify({
    required SignedDeviceApproval approval,
    required SimplePublicKey pinnedApproverSigningPublicKey,
    required String expectedUserUid,
    required String expectedApproverDeviceId,
    required String expectedNewDeviceId,
    required List<int> expectedNewX25519PublicKey,
    required List<int> expectedNewEd25519PublicKey,
    required List<int> expectedChallenge,
    required DateTime nowUtc,
  }) async {
    final claim = approval.claim;
    _validateClaim(claim);

    if (pinnedApproverSigningPublicKey.type != KeyPairType.ed25519 ||
        pinnedApproverSigningPublicKey.bytes.length != 32) {
      throw StateError('Invalid trusted signing public key.');
    }

    if (claim.userUid != expectedUserUid ||
        claim.approverDeviceId != expectedApproverDeviceId ||
        claim.newDeviceId != expectedNewDeviceId ||
        !_equal(claim.newX25519PublicKey, expectedNewX25519PublicKey) ||
        !_equal(claim.newEd25519PublicKey, expectedNewEd25519PublicKey) ||
        !_equal(claim.challenge, expectedChallenge)) {
      throw StateError('Device approval context mismatch.');
    }

    final now = nowUtc.toUtc().millisecondsSinceEpoch;

    if (now >= claim.expiresAtMs ||
        claim.issuedAtMs > now + allowedClockSkewMs) {
      throw StateError('Device approval expired or not yet valid.');
    }

    if (approval.signatureBytes.length != 64) {
      throw StateError('Invalid approval signature length.');
    }

    // Do NOT use a signing public key supplied inside the approval.
    final signature = Signature(
      approval.signatureBytes,
      publicKey: pinnedApproverSigningPublicKey,
    );

    final valid = await _ed25519.verify(
      claim.signingBytes,
      signature: signature,
    );

    if (!valid) {
      throw StateError('Device approval signature verification failed.');
    }
  }

  void _validateClaim(DeviceApprovalClaim claim) {
    if (claim.userUid.trim().isEmpty ||
        claim.approverDeviceId.trim().isEmpty ||
        claim.newDeviceId.trim().isEmpty ||
        claim.approverDeviceId == claim.newDeviceId) {
      throw ArgumentError('Invalid device approval identifiers.');
    }

    for (final value in [
      claim.newX25519PublicKey,
      claim.newEd25519PublicKey,
      claim.challenge,
    ]) {
      if (value.length != 32 ||
          value.any((byte) => byte < 0 || byte > 255) ||
          value.every((byte) => byte == 0)) {
        throw ArgumentError('Invalid device approval key or challenge.');
      }
    }

    final lifetime = claim.expiresAtMs - claim.issuedAtMs;

    if (claim.issuedAtMs <= 0 ||
        lifetime <= 0 ||
        lifetime > maximumLifetimeMs) {
      throw ArgumentError('Invalid device approval lifetime.');
    }
  }

  bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
