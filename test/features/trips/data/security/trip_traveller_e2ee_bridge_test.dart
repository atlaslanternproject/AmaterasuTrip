import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

void main() {
  const tripId = 'trip-test-1';
  const uid = 'member-test-1';

  Future<SecretKey> newKey() => AesGcm.with256bits().newSecretKey();

  const invitation = TripTravellerProfile(
    hasEsimOrInternet: true,
    hasCheckedBaggage: false,
    hasCabinBaggage10Kg: true,
    hasAllergies: true,
    hasIntolerances: false,
    hasMedicalAccessibilityInfo: true,
    allergies: ' Arachidi di test ',
    medicalAccessibilityInfo: ' Accessibilita di test ',
    emergencyContactName: ' Referente di test ',
    emergencyContactPhone: '+39 00000000',
  );

  const edited = TripTravellerProfileData(
    hasEsimOrInternet: false,
    hasCheckedBaggage: true,
    hasCabinBaggage10Kg: false,
    hasAllergies: false,
    hasIntolerances: true,
    hasMedicalAccessibilityInfo: false,
    intolerances: ' Intolleranza di test ',
    emergencyContactName: ' Contatto di test ',
    emergencyContactPhone: '+39 11111111',
  );

  final bridge = TripTravellerE2eeBridge();

  Future<Map<String, dynamic>> sealInvitation(SecretKey key) =>
      bridge.sealInvitation(
        profile: invitation,
        profileKey: key,
        tripId: tripId,
        memberUid: uid,
      );

  Future<TripTravellerProfileData> open(
    Map<String, dynamic> transport,
    SecretKey key, {
    String targetTrip = tripId,
    String targetUid = uid,
  }) => bridge.openMember(
    transport: transport,
    profileKey: key,
    tripId: targetTrip,
    memberUid: targetUid,
  );

  test('invitation exposes only public fields and ciphertext', () async {
    final transport = await sealInvitation(await newKey());

    expect(transport.keys.toSet(), {
      'hasEsimOrInternet',
      'hasCheckedBaggage',
      'hasCabinBaggage10Kg',
      'protectedDetails',
    });

    final serialised = transport.toString();
    expect(serialised, isNot(contains('Arachidi di test')));
    expect(serialised, isNot(contains('Referente di test')));
    expect(transport.containsKey('hasAllergies'), false);
    expect(transport.containsKey('emergencyContactPhone'), false);
  });

  test('invitation decrypts into the existing model', () async {
    final key = await newKey();
    final result = await open(await sealInvitation(key), key);

    expect(result.toMap(), invitation.toMap());
    expect(result.allergies, 'Arachidi di test');
  });

  test('edited profile survives an encrypted roundtrip', () async {
    final key = await newKey();
    final transport = await bridge.sealEditedProfile(
      profile: edited,
      profileKey: key,
      tripId: tripId,
      memberUid: uid,
    );

    final result = await open(transport, key);
    expect(result.toMap(), edited.toMap());
  });

  test('null health answers remain null', () async {
    final key = await newKey();
    const profile = TripTravellerProfileData(
      hasAllergies: null,
      hasIntolerances: null,
      hasMedicalAccessibilityInfo: null,
      allergies: 'Risposta non dichiarata',
    );

    final transport = await bridge.sealEditedProfile(
      profile: profile,
      profileKey: key,
      tripId: tripId,
      memberUid: uid,
    );

    final result = await open(transport, key);

    expect(result.hasAllergies, isNull);
    expect(result.hasIntolerances, isNull);
    expect(result.hasMedicalAccessibilityInfo, isNull);
    expect(result.allergies, profile.allergies);
  });

  test('legacy plaintext is rejected', () async {
    await expectLater(
      open(invitation.toMap(), await newKey()),
      throwsA(isA<FormatException>()),
    );
  });

  test('modified public field is rejected', () async {
    final key = await newKey();
    final transport = await sealInvitation(key);
    final modified = {...transport, 'hasEsimOrInternet': false};

    await expectLater(open(modified, key), throwsA(isA<FormatException>()));
  });

  test('wrong trip cannot decrypt', () async {
    final key = await newKey();

    await expectLater(
      open(await sealInvitation(key), key, targetTrip: 'other-trip'),
      throwsA(isA<Exception>()),
    );
  });

  test('wrong member cannot decrypt', () async {
    final key = await newKey();

    await expectLater(
      open(await sealInvitation(key), key, targetUid: 'other-member'),
      throwsA(isA<Exception>()),
    );
  });

  test('wrong key cannot decrypt', () async {
    final transport = await sealInvitation(await newKey());

    await expectLater(
      open(transport, await newKey()),
      throwsA(isA<Exception>()),
    );
  });
}
