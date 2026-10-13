import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Trust anchor obtained through an independently authenticated process.
///
/// Never create this automatically from an unverified Firebase response.
class TrustedDevicePublicKey {
  const TrustedDevicePublicKey({
    required this.userUid,
    required this.deviceId,
    required this.fingerprint,
  });

  final String userUid;
  final String deviceId;
  final String fingerprint;
}

/// Verifies X25519 public keys against an existing trusted fingerprint.
///
/// Does not create trust, approve devices, or persist private keys.
class TrustedDevicePublicKeyVerifier {
  final Sha256 _sha256 = Sha256();

  Future<String> fingerprint(List<int> publicKeyBytes) async {
    if (publicKeyBytes.length != 32 ||
        publicKeyBytes.any((byte) => byte < 0 || byte > 255) ||
        publicKeyBytes.every((byte) => byte == 0)) {
      throw const FormatException('Invalid X25519 public key bytes.');
    }

    final hash = await _sha256.hash(publicKeyBytes);

    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  Future<void> requireTrusted({
    required TrustedDevicePublicKey trusted,
    required String userUid,
    required String deviceId,
    required List<int> presentedPublicKey,
  }) async {
    if (userUid.isEmpty ||
        deviceId.isEmpty ||
        trusted.fingerprint.isEmpty ||
        trusted.userUid != userUid ||
        trusted.deviceId != deviceId) {
      throw StateError('Device identity is not trusted.');
    }

    final actualFingerprint = await fingerprint(presentedPublicKey);

    if (actualFingerprint != trusted.fingerprint) {
      throw StateError('Device public key verification failed.');
    }
  }
}
