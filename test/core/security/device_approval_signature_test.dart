import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final service = DeviceApprovalSignatureService();
  final ed25519 = Ed25519();
  final x25519 = X25519();

  final now = DateTime.utc(2026, 10, 13, 12);

  late SimpleKeyPair signer;
  late SimplePublicKey signerPublic;
  late SimpleKeyPair attacker;
  late List<int> xPublic;
  late List<int> edPublic;
  late List<int> nonce;
  late DeviceApprovalClaim claim;
  late SignedDeviceApproval approval;

  DeviceApprovalClaim makeClaim({
    String uid = 'user-test',
    String approver = 'android-existing',
    String target = 'web-new',
    List<int>? xKey,
    List<int>? edKey,
    List<int>? challenge,
    int? issued,
    int? expires,
  }) {
    return DeviceApprovalClaim(
      userUid: uid,
      approverDeviceId: approver,
      newDeviceId: target,
      newX25519PublicKey: xKey ?? xPublic,
      newEd25519PublicKey: edKey ?? edPublic,
      challenge: challenge ?? nonce,
      issuedAtMs: issued ?? now.millisecondsSinceEpoch,
      expiresAtMs:
          expires ?? now.add(const Duration(minutes: 3)).millisecondsSinceEpoch,
    );
  }

  Future<void> check({
    SignedDeviceApproval? signed,
    SimplePublicKey? pinned,
    String uid = 'user-test',
    String approver = 'android-existing',
    String target = 'web-new',
    List<int>? xKey,
    List<int>? edKey,
    List<int>? challenge,
    DateTime? at,
  }) {
    return service.verify(
      approval: signed ?? approval,
      pinnedApproverSigningPublicKey: pinned ?? signerPublic,
      expectedUserUid: uid,
      expectedApproverDeviceId: approver,
      expectedNewDeviceId: target,
      expectedNewX25519PublicKey: xKey ?? xPublic,
      expectedNewEd25519PublicKey: edKey ?? edPublic,
      expectedChallenge: challenge ?? nonce,
      nowUtc: at ?? now,
    );
  }

  setUpAll(() async {
    signer = await ed25519.newKeyPair();
    signerPublic = await signer.extractPublicKey();
    attacker = await ed25519.newKeyPair();

    xPublic = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;
    edPublic = (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;
    nonce = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    claim = makeClaim();
    approval = await service.sign(
      claim: claim,
      trustedDeviceSigningKey: signer,
    );
  });

  test('Approva una firma autentica dal dispositivo attendibile', () async {
    await check();
  });

  test('Rifiuta una firma prodotta da un attaccante', () async {
    final forged = await service.sign(
      claim: claim,
      trustedDeviceSigningKey: attacker,
    );

    await expectLater(check(signed: forged), throwsStateError);
  });

  test('Rifiuta una chiave firmataria attendibile diversa', () async {
    final wrong = await attacker.extractPublicKey();

    await expectLater(check(pinned: wrong), throwsStateError);
  });

  test('Rifiuta un altro UID', () async {
    await expectLater(check(uid: 'altra-persona'), throwsStateError);
  });

  test('Rifiuta un dispositivo approvatore diverso', () async {
    await expectLater(check(approver: 'altro-android'), throwsStateError);
  });

  test('Rifiuta un dispositivo destinatario diverso', () async {
    await expectLater(check(target: 'altro-web'), throwsStateError);
  });

  test('Rifiuta una challenge diversa', () async {
    final different = List<int>.filled(32, 42);

    await expectLater(check(challenge: different), throwsStateError);
  });

  test('Rifiuta una chiave X25519 destinataria diversa', () async {
    final different =
        (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    await expectLater(check(xKey: different), throwsStateError);
  });

  test('Rifiuta una chiave Ed25519 destinataria diversa', () async {
    final different =
        (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;

    await expectLater(check(edKey: different), throwsStateError);
  });

  test('Rifiuta una approvazione scaduta', () async {
    await expectLater(
      check(at: now.add(const Duration(minutes: 4))),
      throwsStateError,
    );
  });

  test('Rifiuta una approvazione emessa troppo nel futuro', () async {
    final futureClaim = makeClaim(
      issued: now.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
      expires: now.add(const Duration(minutes: 4)).millisecondsSinceEpoch,
    );

    final signed = await service.sign(
      claim: futureClaim,
      trustedDeviceSigningKey: signer,
    );

    await expectLater(check(signed: signed), throwsStateError);
  });

  test('Rifiuta la modifica dei dati dopo la firma', () async {
    final modified = SignedDeviceApproval(
      claim: makeClaim(target: 'web-manomesso'),
      signatureBytes: approval.signatureBytes,
    );

    await expectLater(
      check(signed: modified, target: 'web-manomesso'),
      throwsStateError,
    );
  });

  test('Rifiuta firme alterate', () async {
    final changed = List<int>.from(approval.signatureBytes);
    changed[0] ^= 1;

    final modified = SignedDeviceApproval(
      claim: claim,
      signatureBytes: changed,
    );

    await expectLater(check(signed: modified), throwsStateError);
  });

  test('Rifiuta una validità eccessiva', () async {
    final invalidClaim = makeClaim(
      expires: now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
    );

    await expectLater(
      service.sign(claim: invalidClaim, trustedDeviceSigningKey: signer),
      throwsArgumentError,
    );
  });

  test('Rifiuta challenge di lunghezza non valida', () async {
    final invalidClaim = makeClaim(challenge: List<int>.filled(8, 7));

    await expectLater(
      service.sign(claim: invalidClaim, trustedDeviceSigningKey: signer),
      throwsArgumentError,
    );
  });
}
