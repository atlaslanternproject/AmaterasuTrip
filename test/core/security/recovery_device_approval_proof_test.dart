import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:amaterasutrip/core/security/first_root_local_identity.dart';
import 'package:amaterasutrip/core/security/recovery_device_approval_proof.dart';

void main() {
  test('Recovery proof contains two valid signatures', () async {
    final rootX = await X25519().newKeyPair();
    final rootEd = await Ed25519().newKeyPair();
    final newX = await X25519().newKeyPair();
    final newEd = await Ed25519().newKeyPair();

    final root = FirstRootLocalIdentity(
      uid: 'audit-user',
      deviceId: 'original-device',
      createdAtMs: 1700000000000,
      exchangePrivate: await rootX.extractPrivateKeyBytes(),
      exchangePublic: (await rootX.extractPublicKey()).bytes,
      signingPrivate: await rootEd.extractPrivateKeyBytes(),
      signingPublic: (await rootEd.extractPublicKey()).bytes,
    );

    final anchor = FirstDeviceTrustAnchor(
      userUid: root.uid,
      deviceId: root.deviceId,
      createdAtMs: root.createdAtMs,
      x25519PublicKey: root.exchangePublic,
      ed25519PublicKey: root.signingPublic,
    );

    final anchors = FirstDeviceTrustAnchorService();
    final signed = await anchors.issue(anchor: anchor, localSigningKey: rootEd);

    final request = await DeviceEnrollmentRequest.create(
      userUid: root.uid,
      newDeviceId: 'new-browser',
      x25519PublicKey: (await newX.extractPublicKey()).bytes,
      ed25519PublicKey: (await newEd.extractPublicKey()).bytes,
      nowUtc: DateTime.utc(2026, 10, 16, 12),
    );

    final proof = await RecoveryDeviceApprovalProofService().create(
      recoveredRoot: root,
      registeredRoot: signed,
      recoveredFingerprint: await anchors.fingerprint(anchor),
      request: request,
      newExchangeKey: newX,
      newSigningKey: newEd,
      nowUtc: DateTime.utc(2026, 10, 16, 12, 1),
    );

    final bytes = proof.approval.claim.signingBytes;

    final rootValid = await Ed25519().verify(
      bytes,
      signature: Signature(
        proof.approval.signatureBytes,
        publicKey: await rootEd.extractPublicKey(),
      ),
    );

    final deviceValid = await Ed25519().verify(
      bytes,
      signature: Signature(
        proof.deviceSignature,
        publicKey: await newEd.extractPublicKey(),
      ),
    );

    expect(rootValid, isTrue);
    expect(deviceValid, isTrue);

    final wire = proof.toWire();
    expect(wire.keys.toSet(), {'approval', 'newDeviceSignature'});
    expect(proof.deviceSignature, hasLength(64));
  });
}
