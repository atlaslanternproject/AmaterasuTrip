import 'package:amaterasutrip/core/security/device_approval_signature.dart';
import 'package:amaterasutrip/core/security/device_enrollment_request.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final x25519 = X25519();
  final ed25519 = Ed25519();
  final approvalService = DeviceApprovalSignatureService();

  final now = DateTime.utc(2026, 10, 13, 12);

  late List<int> xPublic;
  late List<int> edPublic;

  Future<DeviceEnrollmentRequest> create({
    String uid = 'user-test',
    String device = 'web-new',
    List<int>? xKey,
    List<int>? edKey,
    DateTime? issued,
  }) {
    return DeviceEnrollmentRequest.create(
      userUid: uid,
      newDeviceId: device,
      x25519PublicKey: xKey ?? xPublic,
      ed25519PublicKey: edKey ?? edPublic,
      nowUtc: issued ?? now,
    );
  }

  setUpAll(() async {
    xPublic = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;
    edPublic = (await (await ed25519.newKeyPair()).extractPublicKey()).bytes;
  });

  test('QR valido conserva le chiavi pubbliche e la challenge', () async {
    final original = await create();

    final restored = DeviceEnrollmentRequest.fromQrPayload(
      original.toQrPayload(),
      expectedUserUid: 'user-test',
      nowUtc: now,
    );

    expect(restored.userUid, 'user-test');
    expect(restored.newDeviceId, 'web-new');
    expect(restored.x25519PublicKey, orderedEquals(xPublic));
    expect(restored.ed25519PublicKey, orderedEquals(edPublic));
    expect(restored.challenge, orderedEquals(original.challenge));
  });

  test('Due richieste usano challenge differenti', () async {
    final first = await create();
    final second = await create();

    expect(first.challenge, isNot(orderedEquals(second.challenge)));
  });

  test('Rifiuta una richiesta di un altro account', () async {
    final request = await create();

    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        request.toQrPayload(),
        expectedUserUid: 'account-diverso',
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('Rifiuta un prefisso QR sconosciuto', () {
    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        'invalid:abc',
        expectedUserUid: 'user-test',
        nowUtc: now,
      ),
      throwsFormatException,
    );
  });

  test('Rifiuta una richiesta scaduta', () async {
    final request = await create();

    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        request.toQrPayload(),
        expectedUserUid: 'user-test',
        nowUtc: now.add(const Duration(minutes: 4)),
      ),
      throwsStateError,
    );
  });

  test('Rifiuta una richiesta troppo nel futuro', () async {
    final request = await create(issued: now.add(const Duration(minutes: 2)));

    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        request.toQrPayload(),
        expectedUserUid: 'user-test',
        nowUtc: now,
      ),
      throwsStateError,
    );
  });

  test('Rifiuta una chiave pubblica troncata', () async {
    await expectLater(
      create(xKey: List<int>.filled(31, 7)),
      throwsFormatException,
    );
  });

  test('Rifiuta una challenge malformata nel QR', () {
    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        '${DeviceEnrollmentRequest.qrPrefix}***',
        expectedUserUid: 'user-test',
        nowUtc: now,
      ),
      throwsFormatException,
    );
  });

  test('Rifiuta un QR eccessivamente lungo', () {
    final payload = '${DeviceEnrollmentRequest.qrPrefix}${'a' * 2000}';

    expect(
      () => DeviceEnrollmentRequest.fromQrPayload(
        payload,
        expectedUserUid: 'user-test',
        nowUtc: now,
      ),
      throwsFormatException,
    );
  });

  test('Richiesta QR convertibile in approvazione firmata', () async {
    final request = await create();
    final restored = DeviceEnrollmentRequest.fromQrPayload(
      request.toQrPayload(),
      expectedUserUid: 'user-test',
      nowUtc: now,
    );

    final claim = restored.toApprovalClaim(
      approverDeviceId: 'android-existing',
    );

    final signingKey = await ed25519.newKeyPair();
    final signingPublicKey = await signingKey.extractPublicKey();

    final signed = await approvalService.sign(
      claim: claim,
      trustedDeviceSigningKey: signingKey,
    );

    await approvalService.verify(
      approval: signed,
      pinnedApproverSigningPublicKey: signingPublicKey,
      expectedUserUid: 'user-test',
      expectedApproverDeviceId: 'android-existing',
      expectedNewDeviceId: 'web-new',
      expectedNewX25519PublicKey: xPublic,
      expectedNewEd25519PublicKey: edPublic,
      expectedChallenge: request.challenge,
      nowUtc: now,
    );
  });
}
