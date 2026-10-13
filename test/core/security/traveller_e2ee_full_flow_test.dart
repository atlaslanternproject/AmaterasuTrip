import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/authenticated_profile_key_exchange.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';

const _tripId = 'trip-e2ee-test';
const _ownerUid = 'alice-test';

const _profile = TripTravellerProfile(
  hasEsimOrInternet: true,
  hasCheckedBaggage: false,
  hasCabinBaggage10Kg: true,
  hasAllergies: true,
  hasIntolerances: true,
  hasMedicalAccessibilityInfo: true,
  allergies: 'Allergia di prova alle noci',
  intolerances: 'Intolleranza di prova',
  medicalAccessibilityInfo: 'Informazione medica di prova',
  emergencyContactName: 'Contatto di prova',
  emergencyContactPhone: '+39 000000000',
);

class _Scenario {
  _Scenario({
    required this.profileKey,
    required this.aliceEncryption,
    required this.bobEncryption,
    required this.aliceSigning,
    required this.aliceSigningPublic,
    required this.bobEncryptionPublic,
    required this.alicePin,
    required this.bobPin,
  });

  final SecretKey profileKey;
  final SimpleKeyPair aliceEncryption;
  final SimpleKeyPair bobEncryption;
  final SimpleKeyPair aliceSigning;
  final SimplePublicKey aliceSigningPublic;
  final List<int> bobEncryptionPublic;
  final TrustedDevicePublicKey alicePin;
  final TrustedDevicePublicKey bobPin;

  final TripTravellerE2eeBridge bridge = TripTravellerE2eeBridge();
  final AuthenticatedProfileKeyExchange exchange =
      AuthenticatedProfileKeyExchange();

  static Future<_Scenario> create() async {
    final aliceX = await X25519().newKeyPair();
    final bobX = await X25519().newKeyPair();
    final aliceEd = await Ed25519().newKeyPair();
    final alicePublic = await aliceX.extractPublicKey();
    final bobPublic = await bobX.extractPublicKey();
    final verifier = TrustedDevicePublicKeyVerifier();

    // These pins represent independently verified identities
    // ONLY within this controlled test fixture.
    return _Scenario(
      profileKey: await AesGcm.with256bits().newSecretKey(),
      aliceEncryption: aliceX,
      bobEncryption: bobX,
      aliceSigning: aliceEd,
      aliceSigningPublic: await aliceEd.extractPublicKey(),
      bobEncryptionPublic: bobPublic.bytes,
      alicePin: TrustedDevicePublicKey(
        userUid: _ownerUid,
        deviceId: 'alice-android',
        fingerprint: await verifier.fingerprint(alicePublic.bytes),
      ),
      bobPin: TrustedDevicePublicKey(
        userUid: 'bob-test',
        deviceId: 'bob-chrome',
        fingerprint: await verifier.fingerprint(bobPublic.bytes),
      ),
    );
  }

  Future<Map<String, dynamic>> sealProfile() {
    return bridge.sealInvitation(
      profile: _profile,
      profileKey: profileKey,
      tripId: _tripId,
      memberUid: _ownerUid,
    );
  }

  Future<SignedTravellerProfileKeyGrant> issueGrant({
    List<int>? recipientPublic,
  }) {
    return exchange.issue(
      tripId: _tripId,
      profileUid: _ownerUid,
      senderUid: _ownerUid,
      recipientUid: 'bob-test',
      senderDeviceId: 'alice-android',
      recipientDeviceId: 'bob-chrome',
      keyEpoch: 1,
      profileKey: profileKey,
      senderX25519KeyPair: aliceEncryption,
      senderEd25519KeyPair: aliceSigning,
      recipientX25519PublicKey: recipientPublic ?? bobEncryptionPublic,
      trustedRecipient: bobPin,
    );
  }

  Future<SecretKey> receiveGrant(
    SignedTravellerProfileKeyGrant grant, {
    SimpleKeyPair? recipientKey,
  }) {
    return exchange.receive(
      grant: grant,
      expectedTripId: _tripId,
      expectedProfileUid: _ownerUid,
      expectedSenderUid: _ownerUid,
      expectedRecipientUid: 'bob-test',
      expectedSenderDeviceId: 'alice-android',
      expectedRecipientDeviceId: 'bob-chrome',
      expectedKeyEpoch: 1,
      trustedSenderX25519: alicePin,
      pinnedSenderEd25519: aliceSigningPublic,
      recipientX25519KeyPair: recipientKey ?? bobEncryption,
    );
  }
}

void main() {
  test('Alice encrypts; Bob receives the key and decrypts', () async {
    final scenario = await _Scenario.create();

    final encrypted = await scenario.sealProfile();
    final grant = await scenario.issueGrant();
    final bobProfileKey = await scenario.receiveGrant(grant);

    final restored = await scenario.bridge.openMember(
      transport: encrypted,
      profileKey: bobProfileKey,
      tripId: _tripId,
      memberUid: _ownerUid,
    );

    expect(restored.toMap(), _profile.toMap());

    final transportText = encrypted.toString();
    expect(transportText, isNot(contains(_profile.allergies)));
    expect(transportText, isNot(contains(_profile.medicalAccessibilityInfo)));
    expect(encrypted.containsKey('hasAllergies'), false);
  });

  test('Alice rejects a substituted recipient public key', () async {
    final scenario = await _Scenario.create();
    final attacker = await X25519().newKeyPair();
    final attackerPublic = await attacker.extractPublicKey();

    await expectLater(
      scenario.issueGrant(recipientPublic: attackerPublic.bytes),
      throwsA(isA<StateError>()),
    );
  });

  test('intercepted key grant cannot be opened by another device', () async {
    final scenario = await _Scenario.create();
    final grant = await scenario.issueGrant();
    final attacker = await X25519().newKeyPair();

    await expectLater(
      scenario.receiveGrant(grant, recipientKey: attacker),
      throwsA(isA<StateError>()),
    );
  });

  test('tampered encrypted health data cannot be decrypted', () async {
    final scenario = await _Scenario.create();
    final encrypted = await scenario.sealProfile();
    final grant = await scenario.issueGrant();
    final bobKey = await scenario.receiveGrant(grant);

    final envelope = Map<String, dynamic>.from(
      encrypted['protectedDetails'] as Map,
    );

    final original = envelope['ciphertext'] as String;
    expect(original, isNotEmpty);

    envelope['ciphertext'] =
        '${original.startsWith('A') ? 'B' : 'A'}${original.substring(1)}';

    final tampered = <String, dynamic>{
      ...encrypted,
      'protectedDetails': envelope,
    };

    await expectLater(
      scenario.bridge.openMember(
        transport: tampered,
        profileKey: bobKey,
        tripId: _tripId,
        memberUid: _ownerUid,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Bob cannot reuse the key against a different trip or member', () async {
    final scenario = await _Scenario.create();
    final encrypted = await scenario.sealProfile();
    final grant = await scenario.issueGrant();
    final bobKey = await scenario.receiveGrant(grant);

    await expectLater(
      scenario.bridge.openMember(
        transport: encrypted,
        profileKey: bobKey,
        tripId: 'another-trip',
        memberUid: _ownerUid,
      ),
      throwsA(isA<Exception>()),
    );

    await expectLater(
      scenario.bridge.openMember(
        transport: encrypted,
        profileKey: bobKey,
        tripId: _tripId,
        memberUid: 'another-member',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
