import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';

/// Must atomically accept the first use of a challenge and reject all
/// subsequent uses for the same account.
///
/// A production implementation must survive app restarts, concurrent
/// requests and rollback attempts. A Firebase-only ledger is not
/// sufficient against a malicious backend administrator.
abstract interface class DeviceApprovalReplayLedger {
  Future<bool> consumeIfUnused({
    required String userUid,
    required List<int> challenge,
    required int expiresAtMs,
  });
}

/// Verifies a device approval before consuming its one-time challenge.
///
/// The pinned signing key and expected device details must come from
/// previously authenticated sources, not an untrusted Firebase record.
class DeviceApprovalReplayGuard {
  const DeviceApprovalReplayGuard({
    required this.signatureService,
    required this.ledger,
  });

  final DeviceApprovalSignatureService signatureService;
  final DeviceApprovalReplayLedger ledger;

  Future<void> verifyAndConsume({
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
    await signatureService.verify(
      approval: approval,
      pinnedApproverSigningPublicKey: pinnedApproverSigningPublicKey,
      expectedUserUid: expectedUserUid,
      expectedApproverDeviceId: expectedApproverDeviceId,
      expectedNewDeviceId: expectedNewDeviceId,
      expectedNewX25519PublicKey: expectedNewX25519PublicKey,
      expectedNewEd25519PublicKey: expectedNewEd25519PublicKey,
      expectedChallenge: expectedChallenge,
      nowUtc: nowUtc,
    );

    // Never consume an unauthenticated or expired approval.
    // If the ledger is unavailable, its failure propagates:
    // approval must not be granted.
    final firstUse = await ledger.consumeIfUnused(
      userUid: expectedUserUid,
      challenge: expectedChallenge,
      expiresAtMs: approval.claim.expiresAtMs,
    );

    if (!firstUse) {
      throw StateError('Device approval challenge already consumed.');
    }
  }
}
