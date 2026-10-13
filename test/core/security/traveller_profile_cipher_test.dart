import 'dart:convert';

import 'package:amaterasutrip/core/security/traveller_profile_cipher.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  final cipher = TravellerProfileCipher();

  const sensitiveFields = <String, dynamic>{
    'hasAllergies': true,
    'allergies': 'Arachidi - dato fittizio',
    'hasIntolerances': false,
    'intolerances': '',
    'hasMedicalAccessibilityInfo': null,
    'medicalAccessibilityInfo': '',
    'emergencyContactName': 'Persona di test',
    'emergencyContactPhone': '+390000000000',
  };

  Future<EncryptedTravellerProfile> encryptWith(SecretKey key) {
    return cipher.encrypt(
      sensitiveFields: sensitiveFields,
      secretKey: key,
      tripId: 'trip-test',
      memberUid: 'user-test',
    );
  }

  test('Cifra e decifra tutti i campi sensibili', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    final restored = await cipher.decrypt(
      encrypted: encrypted,
      secretKey: key,
      tripId: 'trip-test',
      memberUid: 'user-test',
    );

    expect(restored, sensitiveFields);

    final serialized = jsonEncode(encrypted.toMap());
    expect(serialized, isNot(contains('Arachidi - dato fittizio')));
    expect(serialized, isNot(contains('Persona di test')));
    expect(serialized, isNot(contains('hasAllergies')));
  });

  test('Envelope serializzabile e ripristinabile', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    final envelope = EncryptedTravellerProfile.fromMap(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(encrypted.toMap())) as Map,
      ),
    );

    final restored = await cipher.decrypt(
      encrypted: envelope,
      secretKey: key,
      tripId: 'trip-test',
      memberUid: 'user-test',
    );

    expect(restored, sensitiveFields);
  });

  test('Due cifrature usano nonce differenti', () async {
    final key = await cipher.generateProfileKey();

    final first = await encryptWith(key);
    final second = await encryptWith(key);

    expect(first.nonce, isNot(second.nonce));
    expect(first.ciphertext, isNot(second.ciphertext));
  });

  test('Una chiave diversa non decifra', () async {
    final key = await cipher.generateProfileKey();
    final wrongKey = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    await expectLater(
      cipher.decrypt(
        encrypted: encrypted,
        secretKey: wrongKey,
        tripId: 'trip-test',
        memberUid: 'user-test',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Una modifica al contenuto cifrato viene rilevata', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    final modifiedBytes = base64Decode(encrypted.ciphertext);
    modifiedBytes[0] ^= 1;

    final tampered = EncryptedTravellerProfile(
      nonce: encrypted.nonce,
      ciphertext: base64Encode(modifiedBytes),
      mac: encrypted.mac,
    );

    await expectLater(
      cipher.decrypt(
        encrypted: tampered,
        secretKey: key,
        tripId: 'trip-test',
        memberUid: 'user-test',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Non decifra il profilo associato a un altro viaggio', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    await expectLater(
      cipher.decrypt(
        encrypted: encrypted,
        secretKey: key,
        tripId: 'altro-viaggio',
        memberUid: 'user-test',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Non decifra il profilo associato a un altro utente', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    await expectLater(
      cipher.decrypt(
        encrypted: encrypted,
        secretKey: key,
        tripId: 'trip-test',
        memberUid: 'altro-utente',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Rifiuta formati di cifratura non supportati', () async {
    final key = await cipher.generateProfileKey();
    final encrypted = await encryptWith(key);

    final invalid = encrypted.toMap();
    invalid['version'] = 99;

    expect(
      () => EncryptedTravellerProfile.fromMap(invalid),
      throwsFormatException,
    );
  });
}
