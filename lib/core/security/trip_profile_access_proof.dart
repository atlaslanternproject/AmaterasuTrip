import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Signs an access request locally without exporting private keys.
final class TripProfileAccessProofSigner {
  static List<int> signingBytes(Map<String, dynamic> data) {
    return utf8.encode(
      jsonEncode([
        'amaterasutrip',
        'trip-profile-access-request',
        1,
        data['uid'],
        data['tripId'],
        data['profileUid'],
        data['deviceId'],
        data['nonce'],
        data['issuedAtMs'],
        data['expiresAtMs'],
      ]),
    );
  }

  Future<Map<String, dynamic>> sign({
    required String uid,
    required String tripId,
    required String profileUid,
    required String deviceId,
    required SimpleKeyPair signingKey,
  }) async {
    if (uid.isEmpty ||
        tripId.isEmpty ||
        profileUid.isEmpty ||
        deviceId.isEmpty ||
        uid == profileUid) {
      throw StateError('Invalid access request.');
    }

    final pub = await signingKey.extractPublicKey();

    if (pub.type != KeyPairType.ed25519 || pub.bytes.length != 32) {
      throw StateError('Ed25519 identity required.');
    }

    final secret = await AesGcm.with256bits().newSecretKey();
    final nonceBytes = await secret.extractBytes();
    final nonce = base64UrlEncode(nonceBytes).replaceAll('=', '');

    final issuedAtMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    final claim = <String, dynamic>{
      'uid': uid,
      'tripId': tripId,
      'profileUid': profileUid,
      'deviceId': deviceId,
      'nonce': nonce,
      'issuedAtMs': issuedAtMs,
      'expiresAtMs': issuedAtMs + 120000,
    };

    final signature = await Ed25519().sign(
      signingBytes(claim),
      keyPair: signingKey,
    );

    return {...claim, 'signature': base64Encode(signature.bytes)};
  }
}
