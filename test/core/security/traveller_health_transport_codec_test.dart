import 'dart:convert';

import 'package:test/test.dart';

import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';
import 'package:amaterasutrip/core/security/traveller_profile_cipher.dart';

Map<String, dynamic> sampleProfile() => {
  'hasEsimOrInternet': true,
  'hasCheckedBaggage': false,
  'hasCabinBaggage10Kg': null,
  'hasAllergies': true,
  'hasIntolerances': false,
  'hasMedicalAccessibilityInfo': true,
  'allergies': 'TEST_PEANUT_ALLERGY',
  'intolerances': '',
  'medicalAccessibilityInfo': 'TEST_ACCESSIBILITY_NOTE',
  'emergencyContactName': 'TEST_EMERGENCY_PERSON',
  'emergencyContactPhone': '+39 0000000000',
};

void main() {
  final codec = TravellerHealthTransportCodec();
  final cipher = TravellerProfileCipher();

  test(
    'transport contains only public answers and encrypted details',
    () async {
      final key = await cipher.generateProfileKey();
      final sealed = await codec.seal(
        profile: sampleProfile(),
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      );

      expect(sealed.keys.toSet(), {
        'hasEsimOrInternet',
        'hasCheckedBaggage',
        'hasCabinBaggage10Kg',
        'protectedDetails',
      });

      final serialized = jsonEncode(sealed);
      expect(serialized, isNot(contains('TEST_PEANUT_ALLERGY')));
      expect(serialized, isNot(contains('TEST_ACCESSIBILITY_NOTE')));
      expect(serialized, isNot(contains('TEST_EMERGENCY_PERSON')));
      expect(serialized, isNot(contains('+39 0000000000')));
      expect(serialized, isNot(contains('hasAllergies')));
      expect(serialized, isNot(contains('hasIntolerances')));
      expect(serialized, isNot(contains('hasMedicalAccessibilityInfo')));
    },
  );

  test('authorised key restores the exact profile', () async {
    final key = await cipher.generateProfileKey();
    final original = sampleProfile();

    final sealed = await codec.seal(
      profile: original,
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    final restored = await codec.open(
      transport: sealed,
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    expect(restored, original);
  });

  test('modified public answer is rejected', () async {
    final key = await cipher.generateProfileKey();

    final sealed = await codec.seal(
      profile: sampleProfile(),
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    sealed['hasEsimOrInternet'] = false;

    await expectLater(
      codec.open(
        transport: sealed,
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('modified unanswered public field is rejected', () async {
    final key = await cipher.generateProfileKey();

    final sealed = await codec.seal(
      profile: sampleProfile(),
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    sealed['hasCabinBaggage10Kg'] = true;

    await expectLater(
      codec.open(
        transport: sealed,
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      ),
      throwsA(isA<FormatException>()),
    );
  });
  test('wrong trip or member cannot decrypt', () async {
    final key = await cipher.generateProfileKey();
    final sealed = await codec.seal(
      profile: sampleProfile(),
      profileKey: key,
      tripId: 'trip-a',
      memberUid: 'member-a',
    );

    await expectLater(
      codec.open(
        transport: sealed,
        profileKey: key,
        tripId: 'trip-b',
        memberUid: 'member-a',
      ),
      throwsA(anything),
    );

    await expectLater(
      codec.open(
        transport: sealed,
        profileKey: key,
        tripId: 'trip-a',
        memberUid: 'member-b',
      ),
      throwsA(anything),
    );
  });

  test('tampered authentication tag is rejected', () async {
    final key = await cipher.generateProfileKey();
    final sealed = await codec.seal(
      profile: sampleProfile(),
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    final changed = Map<String, dynamic>.from(sealed);
    final envelope = Map<String, dynamic>.from(
      changed['protectedDetails'] as Map,
    );
    envelope['mac'] = 'AAAAAAAAAAAAAAAAAAAAAA==';
    changed['protectedDetails'] = envelope;

    await expectLater(
      codec.open(
        transport: changed,
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      ),
      throwsA(anything),
    );
  });

  test('unknown plaintext fields are refused before encryption', () async {
    final key = await cipher.generateProfileKey();
    final unsafe = sampleProfile()..['medicalNotes'] = 'SECRET';

    await expectLater(
      codec.seal(
        profile: unsafe,
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('legacy plaintext transport is rejected', () async {
    final key = await cipher.generateProfileKey();

    await expectLater(
      codec.open(
        transport: sampleProfile(),
        profileKey: key,
        tripId: 'trip-test',
        memberUid: 'member-test',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('optional unanswered medical questions roundtrip', () async {
    final key = await cipher.generateProfileKey();
    final original = sampleProfile()
      ..['hasAllergies'] = null
      ..['hasIntolerances'] = null
      ..['hasMedicalAccessibilityInfo'] = null
      ..['allergies'] = ''
      ..['medicalAccessibilityInfo'] = '';

    final sealed = await codec.seal(
      profile: original,
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    final restored = await codec.open(
      transport: sealed,
      profileKey: key,
      tripId: 'trip-test',
      memberUid: 'member-test',
    );

    expect(restored, original);
  });
}
