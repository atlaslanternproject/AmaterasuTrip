import 'dart:convert';

import 'package:amaterasutrip/core/security/device_approval_replay_guard.dart';
import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

/// Test-only simulation. Not suitable for production persistence.
class _FakeAtomicLedger implements DeviceApprovalReplayLedger {
  final Set<String> consumed = {};
  bool available = true;

  @override
  Future<bool> consumeIfUnused({
    required String userUid,
    required List<int> challenge,
    required int expiresAtMs,
  }) async {
    if (!available) {
      throw StateError('Approval ledger unavailable.');
    }

    final identifier = '$userUid:${base64UrlEncode(challenge)}';

    // A Set.add operation is synchronous in this test fake.
    return consumed.add(identifier);
  }
}

void main() {
  final signatures = DeviceApprovalSignatureService();
  final ed25519 = Ed25519();
  final x25519 = X25519();
  final now = DateTime.utc(2026, 10, 13, 12);

  late SimpleKeyPair trustedSigner;
  late SimplePublicKey trustedSigningPublicKey;
  late SimpleKeyPair attackerSigner;
  late List<int> x25519PublicKey;
  late List<int> ed25519PublicKey;

  late _FakeAtomicLedger ledger;
  late DeviceEnrollmentRequest request;
  late SignedDeviceApproval approval;

  Future<DeviceEnrollmentRequest> newRequest() {
    return DeviceEnrollmentRequest.create(
      userUid: 'user-test',
      newDeviceId: 'web-new',
      x25519PublicKey: x25519PublicKey,
      ed25519PublicKey: ed25519PublicKey,
      nowUtc: now,
    );
  }

  Future<SignedDeviceApproval> signRequest(
    DeviceEnrollmentRequest enrollment, {
    SimpleKeyPair? signer,
  }) {
    return signatures.sign(
      claim: enrollment.toApprovalClaim(approverDeviceId: 'android-existing'),
      trustedDeviceSigningKey: signer ?? trustedSigner,
    );
  }

  Future<void> check({
    SignedDeviceApproval? signed,
    DeviceEnrollmentRequest? expected,
    SimplePublicKey? pinnedSigningKey,
    String target = 'web-new',
    DateTime? at,
  }) {
    final expectedRequest = expected ?? request;

    final guard = DeviceApprovalReplayGuard(
      signatureService: signatures,
      ledger: ledger,
    );

    return guard.verifyAndConsume(
      approval: signed ?? approval,
      pinnedApproverSigningPublicKey:
          pinnedSigningKey ?? trustedSigningPublicKey,
      expectedUserUid: 'user-test',
      expectedApproverDeviceId: 'android-existing',
      expectedNewDeviceId: target,
      expectedNewX25519PublicKey: expectedRequest.x25519PublicKey,
      expectedNewEd25519PublicKey: expectedRequest.ed25519PublicKey,
      expectedChallenge: expectedRequest.challenge,
      nowUtc: at ?? now,
    );
  }

  setUpAll(() async {
    trustedSigner = await ed25519.newKeyPair();
    trustedSigningPublicKey = await trustedSigner.extractPublicKey();

    attackerSigner = await ed25519.newKeyPair();

    x25519PublicKey =
        (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    ed25519PublicKey =
        (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;
  });

  setUp(() async {
    ledger = _FakeAtomicLedger();
    request = await newRequest();
    approval = await signRequest(request);
  });

  test('Accetta la prima approvazione autentica', () async {
    await check();
    expect(ledger.consumed.length, 1);
  });

  test('Rifiuta il riutilizzo della stessa approvazione', () async {
    await check();

    await expectLater(check(), throwsStateError);

    expect(ledger.consumed.length, 1);
  });

  test('Rifiuta replay anche con una nuova istanza del guard', () async {
    await check();

    // check() constructs a new guard with the same ledger.
    await expectLater(check(), throwsStateError);
  });

  test('Una firma falsa non consuma la challenge', () async {
    final forged = await signRequest(request, signer: attackerSigner);

    await expectLater(check(signed: forged), throwsStateError);

    expect(ledger.consumed, isEmpty);

    await check();
    expect(ledger.consumed.length, 1);
  });

  test('Un dispositivo diverso non consuma la challenge', () async {
    await expectLater(
      check(target: 'dispositivo-non-previsto'),
      throwsStateError,
    );

    expect(ledger.consumed, isEmpty);

    await check();
  });

  test('Una challenge diversa non viene accettata', () async {
    final unrelated = await newRequest();

    await expectLater(check(expected: unrelated), throwsStateError);

    expect(ledger.consumed, isEmpty);

    await check();
  });

  test('Una approvazione scaduta non consuma la challenge', () async {
    await expectLater(
      check(at: now.add(const Duration(minutes: 4))),
      throwsStateError,
    );

    expect(ledger.consumed, isEmpty);
  });

  test('Archivio indisponibile: autorizzazione bloccata', () async {
    ledger.available = false;

    await expectLater(check(), throwsStateError);

    expect(ledger.consumed, isEmpty);
  });

  test('Firma alterata non consuma la challenge', () async {
    final changed = List<int>.from(approval.signatureBytes);
    changed[0] ^= 1;

    final modified = SignedDeviceApproval(
      claim: approval.claim,
      signatureBytes: changed,
    );

    await expectLater(check(signed: modified), throwsStateError);

    expect(ledger.consumed, isEmpty);
  });

  test('Una nuova richiesta indipendente viene accettata', () async {
    await check();

    final secondRequest = await newRequest();
    final secondApproval = await signRequest(secondRequest);

    await check(signed: secondApproval, expected: secondRequest);

    expect(ledger.consumed.length, 2);
  });

  test('Due richieste concorrenti non passano entrambe', () async {
    Future<bool> attempt() async {
      try {
        await check();
        return true;
      } catch (_) {
        return false;
      }
    }

    final outcomes = await Future.wait([attempt(), attempt()]);

    expect(outcomes.where((result) => result).length, 1);
    expect(ledger.consumed.length, 1);
  });
}
