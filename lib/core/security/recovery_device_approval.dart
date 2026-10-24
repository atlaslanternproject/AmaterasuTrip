import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';
import 'device_enrollment_request.dart';
import 'first_device_trust_anchor.dart';
import 'first_root_local_identity.dart';

/// Signs a new-device request using an independently recovered root.
/// The caller must have verified the recovery kit first.
/// This does not enroll, persist or grant data access.
final class RecoveryDeviceApproval {
  final _anchors = FirstDeviceTrustAnchorService();
  final _approvals = DeviceApprovalSignatureService();

  Future<SignedDeviceApproval> authorise({
    required FirstRootLocalIdentity recoveredRoot,
    required SignedFirstDeviceTrustAnchor registeredRoot,
    required String recoveredFingerprint,
    required DeviceEnrollmentRequest request,
    required SimpleKeyPair newExchangeKey,
    required SimpleKeyPair newSigningKey,
    required DateTime nowUtc,
  }) async {
    final root = registeredRoot.anchor;

    if (recoveredRoot.uid != root.userUid ||
        recoveredRoot.deviceId != root.deviceId ||
        recoveredRoot.createdAtMs != root.createdAtMs ||
        request.userUid != root.userUid ||
        request.newDeviceId == root.deviceId) {
      throw StateError('Recovery device identity mismatch.');
    }

    await _anchors.verifyPinned(
      signed: registeredRoot,
      expectedUserUid: recoveredRoot.uid,
      expectedDeviceId: recoveredRoot.deviceId,
      pinnedFingerprint: recoveredFingerprint,
    );

    // The recovered PRIVATE keys must really match the pinned root.
    final recoveredX = await X25519().newKeyPairFromSeed(
      recoveredRoot.exchangePrivate,
    );
    final recoveredEd = await Ed25519().newKeyPairFromSeed(
      recoveredRoot.signingPrivate,
    );

    if (!_same(
          (await recoveredX.extractPublicKey()).bytes,
          root.x25519PublicKey,
        ) ||
        !_same(
          (await recoveredEd.extractPublicKey()).bytes,
          root.ed25519PublicKey,
        ) ||
        !_same(recoveredRoot.exchangePublic, root.x25519PublicKey) ||
        !_same(recoveredRoot.signingPublic, root.ed25519PublicKey)) {
      throw StateError('Recovered private keys do not match root.');
    }

    // New device must possess the keys it requests to register.
    final xPublic = await newExchangeKey.extractPublicKey();
    final edPublic = await newSigningKey.extractPublicKey();

    if (xPublic.type != KeyPairType.x25519 ||
        edPublic.type != KeyPairType.ed25519 ||
        !_same(xPublic.bytes, request.x25519PublicKey) ||
        !_same(edPublic.bytes, request.ed25519PublicKey)) {
      throw StateError('New device keys do not match request.');
    }

    // Existing enrollment format, without displaying or scanning QR.
    DeviceEnrollmentRequest.fromQrPayload(
      request.toQrPayload(),
      expectedUserUid: recoveredRoot.uid,
      nowUtc: nowUtc,
    );

    final proof = await Ed25519().sign(
      request.challenge,
      keyPair: newSigningKey,
    );

    if (!await Ed25519().verify(request.challenge, signature: proof)) {
      throw StateError('New device ownership proof failed.');
    }

    final claim = request.toApprovalClaim(approverDeviceId: root.deviceId);

    return _approvals.sign(
      claim: claim,
      trustedDeviceSigningKey: recoveredRoot.signingKey,
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
