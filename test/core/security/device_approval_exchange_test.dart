import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/device_approval_exchange.dart';
import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';

void main() {
  final now = DateTime.utc(2026, 10, 13, 19);
  final exchange = DeviceApprovalExchange();

  Future<(DeviceEnrollmentRequest, SignedDeviceApproval, SimplePublicKey)>
  fixture() async {
    final signer = await Ed25519().newKeyPair();
    final exchangeKeys = await X25519().newKeyPair();
    final signingKeys = await Ed25519().newKeyPair();

    final request = await DeviceEnrollmentRequest.create(
      userUid: 'alice',
      newDeviceId: 'new-android',
      x25519PublicKey: (await exchangeKeys.extractPublicKey()).bytes,
      ed25519PublicKey: (await signingKeys.extractPublicKey()).bytes,
      nowUtc: now,
    );

    final approval = await DeviceApprovalSignatureService().sign(
      claim: request.toApprovalClaim(approverDeviceId: 'trusted-android'),
      trustedDeviceSigningKey: signer,
    );

    return (request, approval, await signer.extractPublicKey());
  }

  test('signed approval survives portable encoding', () async {
    final (_, approval, _) = await fixture();

    final payload = exchange.encode(approval);
    final restored = exchange.decodeUntrusted(payload);

    expect(restored.claim.signingBytes, approval.claim.signingBytes);
    expect(restored.signatureBytes, approval.signatureBytes);
  });

  test('verified response matches the original request', () async {
    final (request, approval, trustedKey) = await fixture();

    final verified = await exchange.verifyIncoming(
      payload: exchange.encode(approval),
      localRequest: request,
      trustedApproverDeviceId: 'trusted-android',
      independentlyPinnedApproverKey: trustedKey,
      nowUtc: now,
    );

    expect(verified.signatureBytes, approval.signatureBytes);
  });

  test('another approver signing key is rejected', () async {
    final (request, approval, _) = await fixture();
    final attacker = await Ed25519().newKeyPair();

    await expectLater(
      exchange.verifyIncoming(
        payload: exchange.encode(approval),
        localRequest: request,
        trustedApproverDeviceId: 'trusted-android',
        independentlyPinnedApproverKey: await attacker.extractPublicKey(),
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('another approver device ID is rejected', () async {
    final (request, approval, trustedKey) = await fixture();

    await expectLater(
      exchange.verifyIncoming(
        payload: exchange.encode(approval),
        localRequest: request,
        trustedApproverDeviceId: 'other-device',
        independentlyPinnedApproverKey: trustedKey,
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('another challenge is rejected', () async {
    final (request, approval, trustedKey) = await fixture();

    final differentRequest = await DeviceEnrollmentRequest.create(
      userUid: request.userUid,
      newDeviceId: request.newDeviceId,
      x25519PublicKey: request.x25519PublicKey,
      ed25519PublicKey: request.ed25519PublicKey,
      nowUtc: now,
    );

    await expectLater(
      exchange.verifyIncoming(
        payload: exchange.encode(approval),
        localRequest: differentRequest,
        trustedApproverDeviceId: 'trusted-android',
        independentlyPinnedApproverKey: trustedKey,
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('expired approval is rejected', () async {
    final (request, approval, trustedKey) = await fixture();

    await expectLater(
      exchange.verifyIncoming(
        payload: exchange.encode(approval),
        localRequest: request,
        trustedApproverDeviceId: 'trusted-android',
        independentlyPinnedApproverKey: trustedKey,
        nowUtc: now.add(const Duration(minutes: 4)),
      ),
      throwsStateError,
    );
  });

  test('tampered signature is rejected', () async {
    final (request, approval, trustedKey) = await fixture();

    final tampered = SignedDeviceApproval(
      claim: approval.claim,
      signatureBytes: [
        ...approval.signatureBytes.take(63),
        approval.signatureBytes.last ^ 1,
      ],
    );

    await expectLater(
      exchange.verifyIncoming(
        payload: exchange.encode(tampered),
        localRequest: request,
        trustedApproverDeviceId: 'trusted-android',
        independentlyPinnedApproverKey: trustedKey,
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('invalid and oversized payloads are rejected', () {
    expect(() => exchange.decodeUntrusted('invalid'), throwsFormatException);

    expect(
      () => exchange.decodeUntrusted(
        '${DeviceApprovalExchange.prefix}${'a' * 2000}',
      ),
      throwsFormatException,
    );
  });

  test('unsupported envelope format is rejected', () async {
    final (_, approval, _) = await fixture();
    final payload = exchange.encode(approval);

    final raw = payload.substring(DeviceApprovalExchange.prefix.length);

    final decoded =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(raw))))
            as List<dynamic>;

    decoded[2] = 999;

    final modified =
        '${DeviceApprovalExchange.prefix}${base64UrlEncode(utf8.encode(jsonEncode(decoded))).replaceAll('=', '')}';

    expect(() => exchange.decodeUntrusted(modified), throwsFormatException);
  });
}
