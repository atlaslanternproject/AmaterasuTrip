import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final service = FirstDeviceTrustAnchorService();
  final ed25519 = Ed25519();
  final x25519 = X25519();
  final createdAt = DateTime.utc(2026, 10, 13).millisecondsSinceEpoch;

  late SimpleKeyPair signingKey;
  late SimpleKeyPair attackerKey;
  late List<int> signingPublic;
  late List<int> xPublic;
  late FirstDeviceTrustAnchor root;
  late SignedFirstDeviceTrustAnchor signedRoot;
  late String trustedFingerprint;

  FirstDeviceTrustAnchor makeRoot({
    String uid = 'audit-user',
    String device = 'android-first',
    List<int>? xKey,
    List<int>? edKey,
    int? timestamp,
  }) {
    return FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: device,
      x25519PublicKey: xKey ?? xPublic,
      ed25519PublicKey: edKey ?? signingPublic,
      createdAtMs: timestamp ?? createdAt,
    );
  }

  Future<void> check({
    SignedFirstDeviceTrustAnchor? signed,
    String uid = 'audit-user',
    String device = 'android-first',
    String? pin,
  }) {
    return service.verifyPinned(
      signed: signed ?? signedRoot,
      expectedUserUid: uid,
      expectedDeviceId: device,
      pinnedFingerprint: pin ?? trustedFingerprint,
    );
  }

  setUpAll(() async {
    signingKey = await ed25519.newKeyPair();
    attackerKey = await ed25519.newKeyPair();
    signingPublic = (await signingKey.extractPublicKey()).bytes;
    xPublic = (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    root = makeRoot();
    signedRoot = await service.issue(anchor: root, localSigningKey: signingKey);

    // Simulates a pin originating locally, not from Firebase.
    trustedFingerprint = await service.fingerprint(root);
  });

  test('Identita iniziale autentica con pin corretto', () async {
    await check();
  });

  test('Impronta stabile e codificata in base64url', () async {
    final first = await service.fingerprint(root);
    final second = await service.fingerprint(makeRoot());

    expect(first, second);
    expect(first.length, 43);
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(first), isTrue);
  });

  test('Rifiuta una chiave privata non corrispondente', () async {
    await expectLater(
      service.issue(anchor: root, localSigningKey: attackerKey),
      throwsStateError,
    );
  });

  test('Rifiuta un altro utente', () async {
    await expectLater(check(uid: 'altro-utente'), throwsStateError);
  });

  test('Rifiuta un altro dispositivo', () async {
    await expectLater(check(device: 'altro-dispositivo'), throwsStateError);
  });

  test('Rifiuta una impronta sconosciuta', () async {
    await expectLater(check(pin: 'impronta-non-verificata'), throwsStateError);
  });

  test('Rifiuta chiavi e firma sostituite insieme', () async {
    final attackerPublic = (await attackerKey.extractPublicKey()).bytes;

    final forgedRoot = makeRoot(edKey: attackerPublic);
    final forgedSignature = await service.issue(
      anchor: forgedRoot,
      localSigningKey: attackerKey,
    );

    // Self-signature is valid, but the trusted original pin differs.
    await expectLater(check(signed: forgedSignature), throwsStateError);
  });

  test('Rifiuta sostituzione della chiave X25519', () async {
    final differentX =
        (await (await x25519.newKeyPair()).extractPublicKey()).bytes;

    final modified = SignedFirstDeviceTrustAnchor(
      anchor: makeRoot(xKey: differentX),
      signatureBytes: signedRoot.signatureBytes,
    );

    await expectLater(check(signed: modified), throwsStateError);
  });

  test('Rifiuta alterazione del timestamp', () async {
    final modified = SignedFirstDeviceTrustAnchor(
      anchor: makeRoot(timestamp: createdAt + 1000),
      signatureBytes: signedRoot.signatureBytes,
    );

    await expectLater(check(signed: modified), throwsStateError);
  });

  test('Rifiuta manomissione della firma', () async {
    final changed = List<int>.from(signedRoot.signatureBytes);
    changed[0] ^= 1;

    final modified = SignedFirstDeviceTrustAnchor(
      anchor: root,
      signatureBytes: changed,
    );

    await expectLater(check(signed: modified), throwsStateError);
  });

  test('Rifiuta chiavi pubbliche di lunghezza errata', () async {
    final invalid = makeRoot(edKey: List<int>.filled(31, 7));

    await expectLater(
      service.issue(anchor: invalid, localSigningKey: signingKey),
      throwsArgumentError,
    );
  });

  test('Rifiuta chiave X25519 composta da zeri', () async {
    final invalid = makeRoot(xKey: List<int>.filled(32, 0));

    await expectLater(service.fingerprint(invalid), throwsArgumentError);
  });
}
