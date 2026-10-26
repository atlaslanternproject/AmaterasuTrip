import 'package:amaterasutrip/core/security/account_recovery_kit.dart';
import 'package:amaterasutrip/core/security/account_recovery_vault.dart';
import 'package:amaterasutrip/core/security/first_device_trust_anchor.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  const uid = 'recovery-test-user';
  const deviceId = 'first-device';

  late AccountRecoveryVault vault;
  late AccountRecoveryKitCodec codec;
  late FirstDeviceTrustAnchorService trust;

  late SimpleKeyPair signingKey;
  late FirstDeviceTrustAnchor anchor;
  late SignedFirstDeviceTrustAnchor signedAnchor;

  late String fingerprint;
  late String kitCode;
  late List<int> secret;
  late List<int> portableKey;
  late AccountRecoveryEnvelope envelope;

  setUp(() async {
    vault = AccountRecoveryVault();
    codec = AccountRecoveryKitCodec();
    trust = FirstDeviceTrustAnchorService();

    signingKey = await Ed25519().newKeyPair();
    final publicKey = await signingKey.extractPublicKey();

    anchor = FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: deviceId,
      x25519PublicKey: List<int>.generate(32, (i) => i + 1),
      ed25519PublicKey: publicKey.bytes,
      createdAtMs: 1700000000000,
    );

    signedAnchor = await trust.issue(
      anchor: anchor,
      localSigningKey: signingKey,
    );

    fingerprint = await trust.fingerprint(anchor);
    secret = await vault.generateLocalSecret();
    portableKey = await vault.generateLocalSecret();

    kitCode = await codec.encode(
      userUid: uid,
      rootFingerprint: fingerprint,
      recoverySecret: secret,
    );

    envelope = await vault.seal(
      recoverySecret: secret,
      portableDataKey: portableKey,
      userUid: uid,
      rootFingerprint: fingerprint,
      revision: 1,
    );
  });

  Future<void> checkRoot({
    required SignedFirstDeviceTrustAnchor identity,
    required String pin,
    String expectedUid = uid,
  }) {
    return trust.verifyPinned(
      signed: identity,
      expectedUserUid: expectedUid,
      expectedDeviceId: deviceId,
      pinnedFingerprint: pin,
    );
  }

  test('Il kit autentica la radice e recupera la chiave', () async {
    final imported = await codec.decode(kitCode);

    await checkRoot(identity: signedAnchor, pin: imported.rootFingerprint);

    final recovered = await vault.open(
      envelope: envelope,
      recoverySecret: imported.recoverySecret,
      expectedUserUid: imported.userUid,
      expectedRootFingerprint: imported.rootFingerprint,
      expectedRevision: 1,
    );

    expect(recovered, orderedEquals(portableKey));
  });

  test('Una nuova identita firmata non sostituisce la radice', () async {
    final attackerKey = await Ed25519().newKeyPair();
    final attackerPublic = await attackerKey.extractPublicKey();

    final substituted = FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: deviceId,
      x25519PublicKey: List<int>.filled(32, 17),
      ed25519PublicKey: attackerPublic.bytes,
      createdAtMs: 1700000000000,
    );

    final fakeSigned = await trust.issue(
      anchor: substituted,
      localSigningKey: attackerKey,
    );

    final imported = await codec.decode(kitCode);

    await expectLater(
      checkRoot(identity: fakeSigned, pin: imported.rootFingerprint),
      throwsA(isA<StateError>()),
    );
  });

  test('La sostituzione della chiave X25519 viene rilevata', () async {
    final publicKey = await signingKey.extractPublicKey();

    final substituted = FirstDeviceTrustAnchor(
      userUid: uid,
      deviceId: deviceId,
      x25519PublicKey: List<int>.filled(32, 29),
      ed25519PublicKey: publicKey.bytes,
      createdAtMs: anchor.createdAtMs,
    );

    final altered = await trust.issue(
      anchor: substituted,
      localSigningKey: signingKey,
    );

    await expectLater(
      checkRoot(identity: altered, pin: fingerprint),
      throwsA(isA<StateError>()),
    );
  });

  test('Una firma alterata viene rifiutata', () async {
    final changed = List<int>.from(signedAnchor.signatureBytes);
    changed[0] ^= 1;

    final tampered = SignedFirstDeviceTrustAnchor(
      anchor: anchor,
      signatureBytes: changed,
    );

    await expectLater(
      checkRoot(identity: tampered, pin: fingerprint),
      throwsA(isA<StateError>()),
    );
  });

  test('Una firma valida senza pin indipendente non basta', () async {
    await expectLater(
      checkRoot(identity: signedAnchor, pin: ''),
      throwsA(isA<StateError>()),
    );
  });

  test('Il kit di un altro utente non verifica la radice', () async {
    await expectLater(
      checkRoot(
        identity: signedAnchor,
        pin: fingerprint,
        expectedUid: 'other-user',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('Un codice sostitutivo valido non apre il vault', () async {
    final forgedSecret = await vault.generateLocalSecret();

    final substitutedKit = await codec.encode(
      userUid: uid,
      rootFingerprint: fingerprint,
      recoverySecret: forgedSecret,
    );

    // A checksum is not a signature: this code is syntactically valid.
    final imported = await codec.decode(substitutedKit);

    await expectLater(
      vault.open(
        envelope: envelope,
        recoverySecret: imported.recoverySecret,
        expectedUserUid: uid,
        expectedRootFingerprint: fingerprint,
        expectedRevision: 1,
      ),
      throwsA(anything),
    );
  });

  test('Un backup vecchio viene rifiutato con revisione nota', () async {
    // The expected revision MUST come from independently trusted state.
    // This test does not solve remote rollback detection by itself.
    await expectLater(
      vault.open(
        envelope: envelope,
        recoverySecret: secret,
        expectedUserUid: uid,
        expectedRootFingerprint: fingerprint,
        expectedRevision: 2,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
