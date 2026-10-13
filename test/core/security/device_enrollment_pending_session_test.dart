import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:amaterasutrip/core/security/device_enrollment_pending_session.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final ed25519 = Ed25519();
  final x25519 = X25519();
  final signatures = DeviceApprovalSignatureService();
  final now = DateTime.utc(2026, 10, 13, 12);

  late SimpleKeyPair trustedSigner;
  late SimpleKeyPair attackerSigner;
  late SimplePublicKey trustedPublic;
  late List<int> xPublic;
  late List<int> edPublic;

  late DeviceEnrollmentRequest request;
  late SignedDeviceApproval approval;
  late DeviceEnrollmentPendingSession session;

  Future<DeviceEnrollmentRequest> makeRequest({
    String uid = 'user-test',
    String device = 'web-new',
    List<int>? xKey,
    List<int>? edKey,
  }) {
    return DeviceEnrollmentRequest.create(
      userUid: uid,
      newDeviceId: device,
      x25519PublicKey: xKey ?? xPublic,
      ed25519PublicKey: edKey ?? edPublic,
      nowUtc: now,
    );
  }

  Future<SignedDeviceApproval> signRequest(
    DeviceEnrollmentRequest enrollment, {
    SimpleKeyPair? signer,
    String approver = 'android-existing',
  }) {
    return signatures.sign(
      claim: enrollment.toApprovalClaim(approverDeviceId: approver),
      trustedDeviceSigningKey: signer ?? trustedSigner,
    );
  }

  DeviceEnrollmentPendingSession makeSession({
    DeviceEnrollmentRequest? pendingRequest,
    SimplePublicKey? pinnedKey,
    String approver = 'android-existing',
  }) {
    return DeviceEnrollmentPendingSession(
      localRequest: pendingRequest ?? request,
      trustedApproverDeviceId: approver,
      pinnedApproverSigningPublicKey: pinnedKey ?? trustedPublic,
    );
  }

  setUpAll(() async {
    trustedSigner = await ed25519.newKeyPair();
    attackerSigner = await ed25519.newKeyPair();
    trustedPublic = await trustedSigner.extractPublicKey();

    xPublic = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    edPublic = (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;
  });

  setUp(() async {
    request = await makeRequest();
    approval = await signRequest(request);
    session = makeSession();
  });

  test('Accetta una approvazione autentica una sola volta', () async {
    await session.acceptOnce(approval: approval, nowUtc: now);

    expect(session.isPending, isFalse);
  });

  test('Rifiuta la stessa approvazione dopo il successo', () async {
    await session.acceptOnce(approval: approval, nowUtc: now);

    await expectLater(
      session.acceptOnce(approval: approval, nowUtc: now),
      throwsStateError,
    );
  });

  test('Firma falsa non consuma la richiesta locale', () async {
    final forged = await signRequest(request, signer: attackerSigner);

    await expectLater(
      session.acceptOnce(approval: forged, nowUtc: now),
      throwsStateError,
    );

    expect(session.isPending, isTrue);

    await session.acceptOnce(approval: approval, nowUtc: now);

    expect(session.isPending, isFalse);
  });

  test('Una challenge di altra richiesta viene rifiutata', () async {
    final other = await makeRequest();
    final signedOther = await signRequest(other);

    await expectLater(
      session.acceptOnce(approval: signedOther, nowUtc: now),
      throwsStateError,
    );

    expect(session.isPending, isTrue);
  });

  test('Rifiuta un approvatore diverso', () async {
    final wrong = await signRequest(request, approver: 'altro-telefono');

    await expectLater(
      session.acceptOnce(approval: wrong, nowUtc: now),
      throwsStateError,
    );
  });

  test('Rifiuta una chiave X25519 diversa', () async {
    final otherX = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    final modified = await makeRequest(xKey: otherX);
    final signed = await signRequest(modified);

    await expectLater(
      session.acceptOnce(approval: signed, nowUtc: now),
      throwsStateError,
    );
  });

  test('Rifiuta una chiave Ed25519 diversa', () async {
    final otherEd =
        (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;

    final modified = await makeRequest(edKey: otherEd);
    final signed = await signRequest(modified);

    await expectLater(
      session.acceptOnce(approval: signed, nowUtc: now),
      throwsStateError,
    );
  });

  test('Rifiuta una approvazione di un altro account', () async {
    final other = await makeRequest(uid: 'altro-account');
    final signed = await signRequest(other);

    await expectLater(
      session.acceptOnce(approval: signed, nowUtc: now),
      throwsStateError,
    );
  });

  test('Rifiuta una approvazione scaduta', () async {
    await expectLater(
      session.acceptOnce(
        approval: approval,
        nowUtc: now.add(const Duration(minutes: 4)),
      ),
      throwsStateError,
    );

    expect(session.isPending, isTrue);
  });

  test('Rifiuta una richiesta annullata', () async {
    session.cancel();

    expect(session.isPending, isFalse);

    await expectLater(
      session.acceptOnce(approval: approval, nowUtc: now),
      throwsStateError,
    );
  });

  test('Due accettazioni concorrenti: una sola riesce', () async {
    Future<bool> attempt() async {
      try {
        await session.acceptOnce(approval: approval, nowUtc: now);
        return true;
      } catch (_) {
        return false;
      }
    }

    final results = await Future.wait([attempt(), attempt()]);

    expect(results.where((accepted) => accepted).length, 1);
    expect(session.isPending, isFalse);
  });

  test('Rifiuta la chiave pubblica di un approvatore falso', () async {
    final attackerPublic = await attackerSigner.extractPublicKey();

    final wrongSession = makeSession(pinnedKey: attackerPublic);

    await expectLater(
      wrongSession.acceptOnce(approval: approval, nowUtc: now),
      throwsStateError,
    );

    expect(wrongSession.isPending, isTrue);
  });

  test('Rifiuta approvatore e nuovo dispositivo identici', () {
    expect(() => makeSession(approver: 'web-new'), throwsArgumentError);
  });
}
