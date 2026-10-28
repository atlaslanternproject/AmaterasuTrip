import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/personal_profile_key_vault.dart';
import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';

Map<String, dynamic> fakeProfile() => {
  'hasEsimOrInternet': true,
  'hasCheckedBaggage': false,
  'hasCabinBaggage10Kg': null,
  'hasAllergies': true,
  'hasIntolerances': false,
  'hasMedicalAccessibilityInfo': null,
  'allergies': 'FAKE_TEST_ALLERGY',
  'intolerances': '',
  'medicalAccessibilityInfo': '',
  'emergencyContactName': 'TEST_PERSON',
  'emergencyContactPhone': '+39 0000000000',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Recovery code restores the correct AES key', () async {
    final vault = PersonalProfileKeyVault();
    final key = await AesGcm.with256bits().newSecretKey();

    final code = await vault.exportCode('user-a', 'trip-a', key);

    final restored = vault.parseCode(code, 'user-a', 'trip-a');

    expect(await restored.extractBytes(), await key.extractBytes());

    expect(() => vault.parseCode(code, 'user-b', 'trip-a'), throwsStateError);

    expect(() => vault.parseCode(code, 'user-a', 'trip-b'), throwsStateError);
  });

  test('Recovered key decrypts real AES-GCM ciphertext', () async {
    final vault = PersonalProfileKeyVault();
    final codec = TravellerHealthTransportCodec();
    final key = await AesGcm.with256bits().newSecretKey();

    final original = fakeProfile();

    final encrypted = await codec.seal(
      profile: original,
      profileKey: key,
      tripId: 'trip-a',
      memberUid: 'user-a',
    );

    final serialized = jsonEncode(encrypted);

    expect(serialized, isNot(contains('FAKE_TEST_ALLERGY')));
    expect(serialized, isNot(contains('TEST_PERSON')));

    final code = await vault.exportCode('user-a', 'trip-a', key);
    final recoveredKey = vault.parseCode(code, 'user-a', 'trip-a');

    final decoded = await codec.open(
      transport: encrypted,
      profileKey: recoveredKey,
      tripId: 'trip-a',
      memberUid: 'user-a',
    );

    expect(decoded, original);

    final unrelatedKey = await AesGcm.with256bits().newSecretKey();

    await expectLater(
      codec.open(
        transport: encrypted,
        profileKey: unrelatedKey,
        tripId: 'trip-a',
        memberUid: 'user-a',
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('Chrome persists a staged key without overwriting active', () async {
    final uid = 'vault-test-${DateTime.now().microsecondsSinceEpoch}';
    const tripId = 'local-test-trip';

    final vault = PersonalProfileKeyVault();
    final storage = FlutterSecureStorage();

    String slot(String kind) =>
        'amaterasu:personal-e2ee:v1:$kind:'
        '${base64UrlEncode(utf8.encode(uid))}:'
        '${base64UrlEncode(utf8.encode(tripId))}';

    try {
      expect(await vault.active(uid, tripId), isNull);

      final staged = await vault.stageNew(uid, tripId);

      expect(await vault.active(uid, tripId), isNull);
      expect(await vault.pending(uid, tripId), isNotNull);

      await vault.promote(uid, tripId, staged);

      expect(await vault.pending(uid, tripId), isNull);

      // Simulates creating a fresh vault instance on the same browser.
      final reopenedVault = PersonalProfileKeyVault();
      final reopenedKey = await reopenedVault.active(uid, tripId);

      expect(reopenedKey, isNotNull);

      expect(await reopenedKey!.extractBytes(), await staged.extractBytes());
    } finally {
      // Only remove keys created for this uniquely named test.
      // Never call deleteAll(): real user keys must remain untouched.
      await storage.delete(key: slot('active'));
      await storage.delete(key: slot('pending'));
    }
  }, skip: !kIsWeb);
}
