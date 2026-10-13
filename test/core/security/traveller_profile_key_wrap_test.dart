import 'dart:convert';

import 'package:amaterasutrip/core/security/traveller_profile_key_wrap.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final wrapping = TravellerProfileKeyWrap();
  final x25519 = X25519();

  late List<int> aliceSecret;
  late List<int> bobSecret;
  late List<int> profileKey;
  late WrappedTravellerProfileKey envelope;

  const tripId = 'giappone-test';
  const profileUid = 'alice-user';
  const senderDevice = 'alice-android';
  const recipientDevice = 'bob-web';

  setUpAll(() async {
    final alice = await x25519.newKeyPair();
    final bob = await x25519.newKeyPair();

    aliceSecret = await (await x25519.sharedSecretKey(
      keyPair: alice,
      remotePublicKey: await bob.extractPublicKey(),
    )).extractBytes();

    bobSecret = await (await x25519.sharedSecretKey(
      keyPair: bob,
      remotePublicKey: await alice.extractPublicKey(),
    )).extractBytes();

    profileKey = await (await AesGcm.with256bits().newSecretKey())
        .extractBytes();

    envelope = await wrapping.wrap(
      sharedSecret: aliceSecret,
      profileKey: profileKey,
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDevice,
      recipientDeviceId: recipientDevice,
    );
  });

  Future<List<int>> open({
    List<int>? secret,
    String trip = tripId,
    String owner = profileUid,
    String sender = senderDevice,
    String recipient = recipientDevice,
    WrappedTravellerProfileKey? wrapped,
  }) {
    return wrapping.unwrap(
      envelope: wrapped ?? envelope,
      sharedSecret: secret ?? bobSecret,
      tripId: trip,
      profileUid: owner,
      senderDeviceId: sender,
      recipientDeviceId: recipient,
    );
  }

  test('Alice e Bob ottengono lo stesso segreto X25519', () {
    expect(aliceSecret, orderedEquals(bobSecret));
  });

  test('Bob recupera la chiave del profilo', () async {
    expect(await open(), orderedEquals(profileKey));
  });

  test('Envelope serializzabile senza chiave in chiaro', () {
    final json = jsonEncode(envelope.toMap());
    final restored = WrappedTravellerProfileKey.fromMap(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );

    expect(restored.toMap(), envelope.toMap());
    expect(restored.toMap().containsKey('profileKey'), isFalse);
  });

  test('Un altro viaggio non può riutilizzare il pacchetto', () async {
    await expectLater(
      open(trip: 'altro-viaggio'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Un altro proprietario del profilo viene rifiutato', () async {
    await expectLater(
      open(owner: 'altro-utente'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Un altro dispositivo destinatario viene rifiutato', () async {
    await expectLater(
      open(recipient: 'dispositivo-non-autorizzato'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('La modifica del dispositivo mittente viene rilevata', () async {
    await expectLater(
      open(sender: 'altro-mittente'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Una chiave condivisa errata viene rifiutata', () async {
    final wrong = await x25519.newKeyPair();
    final another = await x25519.newKeyPair();
    final secret = await x25519.sharedSecretKey(
      keyPair: wrong,
      remotePublicKey: await another.extractPublicKey(),
    );

    await expectLater(
      open(secret: await secret.extractBytes()),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Un contenuto cifrato modificato viene rifiutato', () async {
    final changed = base64Decode(envelope.ciphertext);
    changed[0] ^= 1;

    final tampered = WrappedTravellerProfileKey(
      salt: envelope.salt,
      nonce: envelope.nonce,
      ciphertext: base64Encode(changed),
      mac: envelope.mac,
    );

    await expectLater(
      open(wrapped: tampered),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Due condivisioni hanno sali e nonce differenti', () async {
    final second = await wrapping.wrap(
      sharedSecret: aliceSecret,
      profileKey: profileKey,
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDevice,
      recipientDeviceId: recipientDevice,
    );

    expect(second.salt, isNot(envelope.salt));
    expect(second.nonce, isNot(envelope.nonce));
  });

  test('Formati non riconosciuti vengono rifiutati', () {
    final invalid = envelope.toMap();
    invalid['version'] = 99;

    expect(
      () => WrappedTravellerProfileKey.fromMap(invalid),
      throwsFormatException,
    );
  });
}
