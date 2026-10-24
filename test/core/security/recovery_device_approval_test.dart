import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:amaterasutrip/core/security/first_root_local_identity.dart';
import 'package:amaterasutrip/core/security/recovery_device_approval.dart';

final class RecoveryFixture {
  RecoveryFixture(
    this.root,
    this.signed,
    this.fingerprint,
    this.request,
    this.exchange,
    this.signing,
  );

  final FirstRootLocalIdentity root;
  final SignedFirstDeviceTrustAnchor signed;
  final String fingerprint;
  final DeviceEnrollmentRequest request;
  final SimpleKeyPair exchange;
  final SimpleKeyPair signing;
}

Future<RecoveryFixture> fixture() async {
  final x = await X25519().newKeyPair();
  final ed = await Ed25519().newKeyPair();

  final root = FirstRootLocalIdentity(
    uid: 'test-user',
    deviceId: 'original-root-device',
    createdAtMs: 1700000000000,
    exchangePrivate: await x.extractPrivateKeyBytes(),
    exchangePublic: (await x.extractPublicKey()).bytes,
    signingPrivate: await ed.extractPrivateKeyBytes(),
    signingPublic: (await ed.extractPublicKey()).bytes,
  );

  final anchor = FirstDeviceTrustAnchor(
    userUid: root.uid,
    deviceId: root.deviceId,
    createdAtMs: root.createdAtMs,
    x25519PublicKey: root.exchangePublic,
    ed25519PublicKey: root.signingPublic,
  );

  final anchors = FirstDeviceTrustAnchorService();
  final signed = await anchors.issue(anchor: anchor, localSigningKey: ed);

  final newX = await X25519().newKeyPair();
  final newEd = await Ed25519().newKeyPair();

  final request = await DeviceEnrollmentRequest.create(
    userUid: root.uid,
    newDeviceId: 'new-web-browser',
    x25519PublicKey: (await newX.extractPublicKey()).bytes,
    ed25519PublicKey: (await newEd.extractPublicKey()).bytes,
    nowUtc: DateTime.utc(2026, 10, 16, 12),
  );

  return RecoveryFixture(
    root,
    signed,
    await anchors.fingerprint(anchor),
    request,
    newX,
    newEd,
  );
}

Future<SignedDeviceApproval> approve(
  RecoveryFixture f, {
  String? fingerprint,
  SimpleKeyPair? signing,
  DateTime? now,
  FirstRootLocalIdentity? root,
}) {
  return RecoveryDeviceApproval().authorise(
    recoveredRoot: root ?? f.root,
    registeredRoot: f.signed,
    recoveredFingerprint: fingerprint ?? f.fingerprint,
    request: f.request,
    newExchangeKey: f.exchange,
    newSigningKey: signing ?? f.signing,
    nowUtc: now ?? DateTime.utc(2026, 10, 16, 12, 1),
  );
}

void main() {
  group('Recovery device approval', () {
    test('01 - Recovered root signs a new browser identity', () async {
      final f = await fixture();
      final approval = await approve(f);

      await DeviceApprovalSignatureService().verify(
        approval: approval,
        pinnedApproverSigningPublicKey: SimplePublicKey(
          f.root.signingPublic,
          type: KeyPairType.ed25519,
        ),
        expectedUserUid: f.root.uid,
        expectedApproverDeviceId: f.root.deviceId,
        expectedNewDeviceId: f.request.newDeviceId,
        expectedNewX25519PublicKey: f.request.x25519PublicKey,
        expectedNewEd25519PublicKey: f.request.ed25519PublicKey,
        expectedChallenge: f.request.challenge,
        nowUtc: DateTime.utc(2026, 10, 16, 12, 1),
      );
    });

    test('02 - Wrong recovered fingerprint rejected', () async {
      final f = await fixture();

      await expectLater(
        approve(f, fingerprint: 'incorrect-fingerprint'),
        throwsA(isA<StateError>()),
      );
    });

    test('03 - Another browser signing key rejected', () async {
      final f = await fixture();

      await expectLater(
        approve(f, signing: await Ed25519().newKeyPair()),
        throwsA(isA<StateError>()),
      );
    });

    test('04 - Expired enrollment request rejected', () async {
      final f = await fixture();

      await expectLater(
        approve(f, now: DateTime.utc(2026, 10, 16, 12, 4)),
        throwsA(isA<StateError>()),
      );
    });

    test('05 - Mismatched recovered private key rejected', () async {
      final f = await fixture();
      final incorrect = await Ed25519().newKeyPair();

      final altered = FirstRootLocalIdentity(
        uid: f.root.uid,
        deviceId: f.root.deviceId,
        createdAtMs: f.root.createdAtMs,
        exchangePrivate: f.root.exchangePrivate,
        exchangePublic: f.root.exchangePublic,
        signingPrivate: await incorrect.extractPrivateKeyBytes(),
        signingPublic: f.root.signingPublic,
      );

      await expectLater(approve(f, root: altered), throwsA(isA<StateError>()));
    });
  });
}
