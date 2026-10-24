import 'dart:convert';

import 'first_device_trust_anchor.dart';
import 'first_root_local_identity.dart';
import 'first_root_recovery_codec.dart';

/// Parses a server record without automatically trusting it.
final class FirstRootRecoveryRecord {
  FirstRootRecoveryRecord._(this.signed, this.fingerprint, this.envelope);

  final SignedFirstDeviceTrustAnchor signed;
  final String fingerprint;
  final Map<String, dynamic> envelope;

  static const _fields = {
    'version',
    'userUid',
    'deviceId',
    'createdAtMs',
    'x25519PublicKey',
    'ed25519PublicKey',
    'signature',
    'fingerprint',
    'recovery',
  };

  static FirstRootRecoveryRecord fromServer({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    if (data.length != _fields.length ||
        !data.keys.toSet().containsAll(_fields) ||
        data['version'] != 1 ||
        data['userUid'] != uid ||
        data['deviceId'] is! String ||
        data['createdAtMs'] is! int ||
        data['x25519PublicKey'] is! String ||
        data['ed25519PublicKey'] is! String ||
        data['signature'] is! String ||
        data['fingerprint'] is! String ||
        data['recovery'] is! Map) {
      throw const FormatException('Invalid remote recovery record.');
    }

    final anchor = FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: data['deviceId'] as String,
      createdAtMs: data['createdAtMs'] as int,
      x25519PublicKey: base64Decode(data['x25519PublicKey'] as String),
      ed25519PublicKey: base64Decode(data['ed25519PublicKey'] as String),
    );

    return FirstRootRecoveryRecord._(
      SignedFirstDeviceTrustAnchor(
        anchor: anchor,
        signatureBytes: base64Decode(data['signature'] as String),
      ),
      data['fingerprint'] as String,
      Map<String, dynamic>.from(data['recovery'] as Map),
    );
  }

  /// Recovers only after verifying the user-held secret and root.
  /// Does not approve, enroll or persist a device.
  Future<FirstRootLocalIdentity> recover(String recoveryCode) async {
    final actual = await FirstDeviceTrustAnchorService().fingerprint(
      signed.anchor,
    );

    if (actual != fingerprint) {
      throw StateError('Remote root fingerprint mismatch.');
    }

    return FirstRootRecoveryCodec().recover(
      recoveryCode: recoveryCode,
      expectedUserUid: signed.anchor.userUid,
      signed: signed,
      envelope: envelope,
    );
  }
}
