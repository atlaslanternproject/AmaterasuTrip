import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'device_approval_signature.dart';
import 'device_enrollment_request.dart';

/// Portable signed approval.
/// The payload is untrusted until verified against an independently
/// pinned public key. Parsing never authorises a device.
final class DeviceApprovalExchange {
  static const prefix = 'amaterasu-approval-v1:';
  static const maximumLength = 1500;

  String encode(SignedDeviceApproval approval) {
    _validate(approval);
    final claim = approval.claim;

    final values = [
      'amaterasutrip',
      'signed-device-approval',
      1,
      claim.userUid,
      claim.approverDeviceId,
      claim.newDeviceId,
      base64Encode(claim.newX25519PublicKey),
      base64Encode(claim.newEd25519PublicKey),
      base64Encode(claim.challenge),
      claim.issuedAtMs,
      claim.expiresAtMs,
      base64Encode(approval.signatureBytes),
    ];

    final encoded = base64UrlEncode(
      utf8.encode(jsonEncode(values)),
    ).replaceAll('=', '');

    final payload = '$prefix$encoded';

    if (payload.length > maximumLength) {
      throw const FormatException('Approval payload too large.');
    }

    return payload;
  }

  SignedDeviceApproval decodeUntrusted(String payload) {
    if (!payload.startsWith(prefix) || payload.length > maximumLength) {
      throw const FormatException('Invalid approval payload.');
    }

    late final List<dynamic> data;

    try {
      final raw = payload.substring(prefix.length);

      final parsed = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(raw))),
      );

      if (parsed is! List || parsed.length != 12) {
        throw const FormatException('Invalid approval structure.');
      }

      data = parsed;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid approval encoding.');
    }

    if (data[0] != 'amaterasutrip' ||
        data[1] != 'signed-device-approval' ||
        data[2] != 1 ||
        data[3] is! String ||
        data[4] is! String ||
        data[5] is! String ||
        data[6] is! String ||
        data[7] is! String ||
        data[8] is! String ||
        data[9] is! int ||
        data[10] is! int ||
        data[11] is! String) {
      throw const FormatException('Unsupported approval format.');
    }

    late final SignedDeviceApproval approval;

    try {
      approval = SignedDeviceApproval(
        claim: DeviceApprovalClaim(
          userUid: data[3] as String,
          approverDeviceId: data[4] as String,
          newDeviceId: data[5] as String,
          newX25519PublicKey: base64Decode(data[6] as String),
          newEd25519PublicKey: base64Decode(data[7] as String),
          challenge: base64Decode(data[8] as String),
          issuedAtMs: data[9] as int,
          expiresAtMs: data[10] as int,
        ),
        signatureBytes: base64Decode(data[11] as String),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid approval encoding.');
    }

    _validate(approval);

    if (encode(approval) != payload) {
      throw const FormatException('Noncanonical approval payload.');
    }

    return approval;
  }

  Future<SignedDeviceApproval> verifyIncoming({
    required String payload,
    required DeviceEnrollmentRequest localRequest,
    required String trustedApproverDeviceId,
    required SimplePublicKey independentlyPinnedApproverKey,
    required DateTime nowUtc,
  }) async {
    final approval = decodeUntrusted(payload);

    await DeviceApprovalSignatureService().verify(
      approval: approval,
      pinnedApproverSigningPublicKey: independentlyPinnedApproverKey,
      expectedUserUid: localRequest.userUid,
      expectedApproverDeviceId: trustedApproverDeviceId,
      expectedNewDeviceId: localRequest.newDeviceId,
      expectedNewX25519PublicKey: localRequest.x25519PublicKey,
      expectedNewEd25519PublicKey: localRequest.ed25519PublicKey,
      expectedChallenge: localRequest.challenge,
      nowUtc: nowUtc,
    );

    return approval;
  }

  void _validate(SignedDeviceApproval approval) {
    final claim = approval.claim;

    if (claim.userUid.trim().isEmpty ||
        claim.approverDeviceId.trim().isEmpty ||
        claim.newDeviceId.trim().isEmpty ||
        claim.userUid.length > 128 ||
        claim.approverDeviceId.length > 128 ||
        claim.newDeviceId.length > 128 ||
        claim.approverDeviceId == claim.newDeviceId ||
        approval.signatureBytes.length != 64 ||
        claim.issuedAtMs <= 0 ||
        claim.expiresAtMs <= claim.issuedAtMs ||
        claim.expiresAtMs - claim.issuedAtMs >
            DeviceApprovalSignatureService.maximumLifetimeMs) {
      throw const FormatException('Invalid approval metadata.');
    }

    for (final identifier in [
      claim.userUid,
      claim.approverDeviceId,
      claim.newDeviceId,
    ]) {
      if (identifier.codeUnits.any((code) => code < 32)) {
        throw const FormatException('Invalid approval identifier.');
      }
    }

    for (final value in [
      claim.newX25519PublicKey,
      claim.newEd25519PublicKey,
      claim.challenge,
    ]) {
      if (value.length != 32 ||
          value.any((b) => b < 0 || b > 255) ||
          value.every((b) => b == 0)) {
        throw const FormatException('Invalid approval key material.');
      }
    }
  }
}
