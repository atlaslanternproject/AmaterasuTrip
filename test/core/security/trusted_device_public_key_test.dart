import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final verifier = TrustedDevicePublicKeyVerifier();
  final x25519 = X25519();

  late List<int> bobPublicKey;
  late List<int> otherPublicKey;
  late TrustedDevicePublicKey trusted;

  setUpAll(() async {
    final bob = await x25519.newKeyPair();
    final other = await x25519.newKeyPair();

    bobPublicKey = (await bob.extractPublicKey()).bytes;
    otherPublicKey = (await other.extractPublicKey()).bytes;

    trusted = TrustedDevicePublicKey(
      userUid: 'bob-user',
      deviceId: 'bob-web',
      fingerprint: await verifier.fingerprint(bobPublicKey),
    );
  });

  Future<void> verify({
    String uid = 'bob-user',
    String device = 'bob-web',
    List<int>? key,
  }) {
    return verifier.requireTrusted(
      trusted: trusted,
      userUid: uid,
      deviceId: device,
      presentedPublicKey: key ?? bobPublicKey,
    );
  }

  test('Genera un fingerprint SHA-256 stabile', () async {
    final first = await verifier.fingerprint(bobPublicKey);
    final second = await verifier.fingerprint(bobPublicKey);

    expect(first, second);
    expect(first.length, 43);
  });

  test('Accetta una chiave già verificata', () async {
    await verify();
  });

  test('Rifiuta la sostituzione della chiave pubblica', () async {
    await expectLater(verify(key: otherPublicKey), throwsStateError);
  });

  test('Rifiuta un altro utente', () async {
    await expectLater(verify(uid: 'alice-user'), throwsStateError);
  });

  test('Rifiuta un altro dispositivo', () async {
    await expectLater(
      verify(device: 'dispositivo-sconosciuto'),
      throwsStateError,
    );
  });

  test('Rifiuta una chiave pubblica troncata', () async {
    await expectLater(
      verifier.fingerprint(List<int>.filled(31, 1)),
      throwsFormatException,
    );
  });

  test('Rifiuta una chiave pubblica tutta zero', () async {
    await expectLater(
      verifier.fingerprint(List<int>.filled(32, 0)),
      throwsFormatException,
    );
  });

  test('Rileva una rotazione di chiave non approvata', () async {
    final changed = await x25519.newKeyPair();
    final newPublicKey = (await changed.extractPublicKey()).bytes;

    await expectLater(verify(key: newPublicKey), throwsStateError);
  });
}
