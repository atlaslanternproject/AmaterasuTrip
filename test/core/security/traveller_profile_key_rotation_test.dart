import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/traveller_profile_key_rotation.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

const _trip = 'trip-rotation-test';
const _owner = 'alice';

const _profile = TripTravellerProfileData(
  hasEsimOrInternet: true,
  hasAllergies: true,
  hasIntolerances: true,
  hasMedicalAccessibilityInfo: true,
  allergies: 'Allergia di test al sesamo',
  intolerances: 'Intolleranza di test',
  medicalAccessibilityInfo: 'Accessibilita riservata',
  emergencyContactName: 'Contatto riservato',
  emergencyContactPhone: '+39 123456789',
);

class _Fixture {
  _Fixture({
    required this.aliceX,
    required this.bobX,
    required this.marcoX,
    required this.aliceEd,
    required this.aliceEdPublic,
    required this.aliceRecipient,
    required this.bobRecipient,
    required this.marcoRecipient,
    required this.alicePin,
  });

  final SimpleKeyPair aliceX;
  final SimpleKeyPair bobX;
  final SimpleKeyPair marcoX;
  final SimpleKeyPair aliceEd;
  final SimplePublicKey aliceEdPublic;
  final ProfileRotationRecipient aliceRecipient;
  final ProfileRotationRecipient bobRecipient;
  final ProfileRotationRecipient marcoRecipient;
  final TrustedDevicePublicKey alicePin;

  final TravellerProfileKeyRotation service = TravellerProfileKeyRotation();

  static Future<_Fixture> create() async {
    final x = X25519();
    final aliceX = await x.newKeyPair();
    final bobX = await x.newKeyPair();
    final marcoX = await x.newKeyPair();
    final aliceEd = await Ed25519().newKeyPair();

    final verifier = TrustedDevicePublicKeyVerifier();

    Future<ProfileRotationRecipient> recipient(
      String uid,
      String deviceId,
      SimpleKeyPair pair,
    ) async {
      final publicKey = await pair.extractPublicKey();

      return ProfileRotationRecipient(
        uid: uid,
        deviceId: deviceId,
        x25519PublicKey: publicKey.bytes,
        trustedPublicKey: TrustedDevicePublicKey(
          userUid: uid,
          deviceId: deviceId,
          fingerprint: await verifier.fingerprint(publicKey.bytes),
        ),
      );
    }

    final alice = await recipient('alice', 'alice-android', aliceX);
    final bob = await recipient('bob', 'bob-chrome', bobX);
    final marco = await recipient('marco', 'marco-android', marcoX);

    return _Fixture(
      aliceX: aliceX,
      bobX: bobX,
      marcoX: marcoX,
      aliceEd: aliceEd,
      aliceEdPublic: await aliceEd.extractPublicKey(),
      aliceRecipient: alice,
      bobRecipient: bob,
      marcoRecipient: marco,
      alicePin: alice.trustedPublicKey,
    );
  }

  Future<SignedProfileKeyRotation> rotate({
    List<ProfileRotationRecipient>? recipients,
    Set<String> revoked = const {'marco'},
  }) {
    return service.rotate(
      profile: _profile,
      tripId: _trip,
      profileUid: _owner,
      senderDeviceId: 'alice-android',
      previousEpoch: 1,
      revokedMemberUids: revoked,
      activeRecipients: recipients ?? [aliceRecipient, bobRecipient],
      senderX25519KeyPair: aliceX,
      senderEd25519KeyPair: aliceEd,
    );
  }

  Future<TripTravellerProfileData> bobOpens(
    SignedProfileKeyRotation rotation, {
    SimpleKeyPair? keyPair,
    SimplePublicKey? signer,
    int minimumEpoch = 2,
  }) {
    return service.openForRecipient(
      rotation: rotation,
      expectedTripId: _trip,
      expectedProfileUid: _owner,
      expectedSenderDeviceId: 'alice-android',
      recipientUid: 'bob',
      recipientDeviceId: 'bob-chrome',
      minimumTrustedEpoch: minimumEpoch,
      trustedSenderX25519: alicePin,
      pinnedSenderEd25519: signer ?? aliceEdPublic,
      recipientX25519KeyPair: keyPair ?? bobX,
    );
  }
}

SignedProfileKeyRotation forgedCopy(
  SignedProfileKeyRotation original, {
  Map<String, dynamic>? encryptedProfile,
  List<int>? signature,
}) {
  return SignedProfileKeyRotation(
    tripId: original.tripId,
    profileUid: original.profileUid,
    senderDeviceId: original.senderDeviceId,
    epoch: original.epoch,
    encryptedProfile: encryptedProfile ?? original.encryptedProfile,
    grants: original.grants,
    revokedMemberUids: original.revokedMemberUids,
    signatureBytes: signature ?? original.signatureBytes,
  );
}

void main() {
  test('Alice rotates: Bob decrypts the new questionnaire', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    expect(rotation.epoch, 2);
    expect((await f.bobOpens(rotation)).toMap(), _profile.toMap());

    final stored = rotation.encryptedProfile.toString();
    expect(stored, isNot(contains(_profile.allergies)));
    expect(stored, isNot(contains(_profile.emergencyContactName)));
  });

  test('Marco receives no grant after removal', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    expect(rotation.revokedMemberUids, ['marco']);
    expect(
      rotation.grants.any((grant) => grant.recipientUid == 'marco'),
      false,
    );

    await expectLater(
      f.service.openForRecipient(
        rotation: rotation,
        expectedTripId: _trip,
        expectedProfileUid: _owner,
        expectedSenderDeviceId: 'alice-android',
        recipientUid: 'marco',
        recipientDeviceId: 'marco-android',
        minimumTrustedEpoch: 2,
        trustedSenderX25519: f.alicePin,
        pinnedSenderEd25519: f.aliceEdPublic,
        recipientX25519KeyPair: f.marcoX,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('rotation fails if Marco is included as recipient', () async {
    final f = await _Fixture.create();

    await expectLater(
      f.rotate(
        recipients: [f.aliceRecipient, f.bobRecipient, f.marcoRecipient],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('changing encrypted content invalidates the signature', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    final modified = <String, dynamic>{
      ...rotation.encryptedProfile,
      'hasEsimOrInternet': false,
    };

    await expectLater(
      f.bobOpens(forgedCopy(rotation, encryptedProfile: modified)),
      throwsA(isA<StateError>()),
    );
  });

  test('forged rotation signature is rejected', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    await expectLater(
      f.bobOpens(forgedCopy(rotation, signature: List<int>.filled(64, 0))),
      throwsA(isA<StateError>()),
    );
  });

  test('an old signed epoch is rejected with trusted epoch floor', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    await expectLater(
      f.bobOpens(rotation, minimumEpoch: 3),
      throwsA(isA<StateError>()),
    );
  });

  test('another device cannot use Bob original key grant', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();

    await expectLater(
      f.bobOpens(rotation, keyPair: f.marcoX),
      throwsA(isA<StateError>()),
    );
  });

  test('substituting the profile owner signing key fails', () async {
    final f = await _Fixture.create();
    final rotation = await f.rotate();
    final attacker = await Ed25519().newKeyPair();

    await expectLater(
      f.bobOpens(rotation, signer: await attacker.extractPublicKey()),
      throwsA(isA<StateError>()),
    );
  });
}
