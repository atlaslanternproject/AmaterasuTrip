import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';
import 'device_enrollment_request.dart';
import 'first_device_trust_anchor.dart';
import 'first_root_local_identity.dart';
import 'recovery_device_approval.dart';

/// Two signatures over the same device-approval claim.
final class RecoveryDeviceApprovalProof {
  const RecoveryDeviceApprovalProof({
    required this.approval,
    required this.deviceSignature,
  });

  final SignedDeviceApproval approval;
  final List<int> deviceSignature;

  Map<String, dynamic> toWire() {
    final claim = approval.claim;

    return {
      'approval': {
        'claim': {
          'userUid': claim.userUid,
          'approverDeviceId': claim.approverDeviceId,
          'newDeviceId': claim.newDeviceId,
          'newX25519PublicKey': base64Encode(claim.newX25519PublicKey),
          'newEd25519PublicKey': base64Encode(claim.newEd25519PublicKey),
          'challenge': base64Encode(claim.challenge),
          'issuedAtMs': claim.issuedAtMs,
          'expiresAtMs': claim.expiresAtMs,
        },
        'signature': base64Encode(approval.signatureBytes),
      },
      'newDeviceSignature': base64Encode(deviceSignature),
    };
  }
}

/// Creates a proof but does not register or trust a device.
final class RecoveryDeviceApprovalProofService {
  Future<RecoveryDeviceApprovalProof> create({
    required FirstRootLocalIdentity recoveredRoot,
    required SignedFirstDeviceTrustAnchor registeredRoot,
    required String recoveredFingerprint,
    required DeviceEnrollmentRequest request,
    required SimpleKeyPair newExchangeKey,
    required SimpleKeyPair newSigningKey,
    required DateTime nowUtc,
  }) async {
    final approval = await RecoveryDeviceApproval().authorise(
      recoveredRoot: recoveredRoot,
      registeredRoot: registeredRoot,
      recoveredFingerprint: recoveredFingerprint,
      request: request,
      newExchangeKey: newExchangeKey,
      newSigningKey: newSigningKey,
      nowUtc: nowUtc,
    );

    final proof = await Ed25519().sign(
      approval.claim.signingBytes,
      keyPair: newSigningKey,
    );

    return RecoveryDeviceApprovalProof(
      approval: approval,
      deviceSignature: List<int>.unmodifiable(proof.bytes),
    );
  }
}
