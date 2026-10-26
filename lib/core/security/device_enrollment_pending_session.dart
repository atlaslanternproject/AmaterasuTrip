import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';
import 'device_enrollment_request.dart';

/// An in-memory, single-use enrollment session on the NEW device.
///
/// The request must have been created locally using public keys
/// corresponding to private keys held by this device.
///
/// The trusted approver signing key must already be authenticated.
/// Never trust a public key solely because Firebase returns it.
///
/// This class is not persistent and does not replace secure recovery,
/// revocation checks or a production device registry.
class DeviceEnrollmentPendingSession {
  DeviceEnrollmentPendingSession({
    required this.localRequest,
    required this.trustedApproverDeviceId,
    required this.pinnedApproverSigningPublicKey,
    DeviceApprovalSignatureService? signatureService,
  }) : _signatureService =
           signatureService ?? DeviceApprovalSignatureService() {
    if (trustedApproverDeviceId.trim().isEmpty ||
        trustedApproverDeviceId == localRequest.newDeviceId) {
      throw ArgumentError('Invalid trusted approver device.');
    }

    if (pinnedApproverSigningPublicKey.type != KeyPairType.ed25519 ||
        pinnedApproverSigningPublicKey.bytes.length != 32) {
      throw ArgumentError('Invalid pinned approver signing key.');
    }
  }

  final DeviceEnrollmentRequest localRequest;
  final String trustedApproverDeviceId;
  final SimplePublicKey pinnedApproverSigningPublicKey;
  final DeviceApprovalSignatureService _signatureService;

  bool _pending = true;
  bool _verifying = false;

  bool get isPending => _pending;

  void cancel() {
    _pending = false;
  }

  Future<void> acceptOnce({
    required SignedDeviceApproval approval,
    required DateTime nowUtc,
  }) async {
    if (!_pending) {
      throw StateError('Enrollment is no longer pending.');
    }

    if (_verifying) {
      throw StateError('Enrollment verification already in progress.');
    }

    _verifying = true;

    try {
      await _signatureService.verify(
        approval: approval,
        pinnedApproverSigningPublicKey: pinnedApproverSigningPublicKey,
        expectedUserUid: localRequest.userUid,
        expectedApproverDeviceId: trustedApproverDeviceId,
        expectedNewDeviceId: localRequest.newDeviceId,
        expectedNewX25519PublicKey: localRequest.x25519PublicKey,
        expectedNewEd25519PublicKey: localRequest.ed25519PublicKey,
        expectedChallenge: localRequest.challenge,
        nowUtc: nowUtc,
      );

      // Cancellation during asynchronous verification must win.
      if (!_pending) {
        throw StateError('Enrollment was cancelled.');
      }

      // Consume synchronously, before returning success.
      // Any subsequent use of this session is rejected.
      _pending = false;
    } finally {
      _verifying = false;
    }
  }
}
