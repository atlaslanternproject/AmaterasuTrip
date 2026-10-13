import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/signed_trip_device_roster.dart';
import 'package:amaterasutrip/core/security/traveller_profile_key_rotation.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:amaterasutrip/core/security/verified_trip_profile_sessions.dart';
import 'package:amaterasutrip/core/security/verified_trip_rotation_reader.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

const tripId = 'integration-trip';
const profile = TripTravellerProfileData(
  hasAllergies: true,
  allergies: 'Private allergy test',
  emergencyContactPhone: '+39 000',
);

class TestEpochs implements TrustedTripEpochStore {
  TestEpochs(this.floor);
  int? floor;
  bool failWrite = false;

  @override
  Future<int?> readTrustedFloor(String tripId) async => floor;

  @override
  Future<void> advanceTrustedFloor(String tripId, int verifiedEpoch) async {
    if (failWrite || floor == null || verifiedEpoch < floor!) {
      throw StateError('Cannot persist trusted epoch.');
    }
    floor = verifiedEpoch;
  }
}

class Fixture {
  Fixture({
    required this.aliceX,
    required this.bobX,
    required this.aliceEd,
    required this.aliceSigner,
    required this.alicePin,
    required this.roster,
    required this.rotation,
  });

  final SimpleKeyPair aliceX;
  final SimpleKeyPair bobX;
  final SimpleKeyPair aliceEd;
  final SimplePublicKey aliceSigner;
  final TrustedDevicePublicKey alicePin;
  final SignedTripDeviceRoster roster;
  final SignedProfileKeyRotation rotation;

  static Future<Fixture> create() async {
    final aliceX = await X25519().newKeyPair();
    final bobX = await X25519().newKeyPair();
    final aliceEd = await Ed25519().newKeyPair();
    final bobEd = await Ed25519().newKeyPair();
    final aliceXP = await aliceX.extractPublicKey();
    final bobXP = await bobX.extractPublicKey();
    final aliceSigner = await aliceEd.extractPublicKey();
    final bobSigner = await bobEd.extractPublicKey();
    final finger = TrustedDevicePublicKeyVerifier();
    final alicePin = TrustedDevicePublicKey(
      userUid: 'alice',
      deviceId: 'alice-android',
      fingerprint: await finger.fingerprint(aliceXP.bytes),
    );
    final bobPin = TrustedDevicePublicKey(
      userUid: 'bob',
      deviceId: 'bob-chrome',
      fingerprint: await finger.fingerprint(bobXP.bytes),
    );
    final recipients = [
      ProfileRotationRecipient(
        uid: 'alice',
        deviceId: 'alice-android',
        x25519PublicKey: aliceXP.bytes,
        trustedPublicKey: alicePin,
      ),
      ProfileRotationRecipient(
        uid: 'bob',
        deviceId: 'bob-chrome',
        x25519PublicKey: bobXP.bytes,
        trustedPublicKey: bobPin,
      ),
    ];
    final roster = await SignedTripDeviceRosterVerifier().sign(
      tripId: tripId,
      authorityUid: 'alice',
      authorityDeviceId: 'alice-android',
      epoch: 2,
      activeDevices: [
        RosterDevice(
          uid: 'alice',
          deviceId: 'alice-android',
          x25519Fingerprint: alicePin.fingerprint,
          ed25519PublicKeyBytes: aliceSigner.bytes,
        ),
        RosterDevice(
          uid: 'bob',
          deviceId: 'bob-chrome',
          x25519Fingerprint: bobPin.fingerprint,
          ed25519PublicKeyBytes: bobSigner.bytes,
        ),
      ],
      revokedMemberUids: {'marco'},
      authorityEd25519KeyPair: aliceEd,
    );
    final rotation = await TravellerProfileKeyRotation().rotate(
      profile: profile,
      tripId: tripId,
      profileUid: 'alice',
      senderDeviceId: 'alice-android',
      previousEpoch: 1,
      revokedMemberUids: {'marco'},
      activeRecipients: recipients,
      senderX25519KeyPair: aliceX,
      senderEd25519KeyPair: aliceEd,
    );
    return Fixture(
      aliceX: aliceX,
      bobX: bobX,
      aliceEd: aliceEd,
      aliceSigner: aliceSigner,
      alicePin: alicePin,
      roster: roster,
      rotation: rotation,
    );
  }

  Future<void> unlock(
    VerifiedTripProfileSessions sessions,
    TestEpochs floor, {
    SimplePublicKey? signer,
    SimpleKeyPair? recipientKey,
  }) async {
    await sessions.unlockFromVerifiedRotation(
      roster: roster,
      rotation: rotation,
      tripId: tripId,
      authorityUid: 'alice',
      authorityDeviceId: 'alice-android',
      pinnedAuthorityEd25519: signer ?? aliceSigner,
      trustedSenderX25519: alicePin,
      pinnedSenderEd25519: aliceSigner,
      recipientUid: 'bob',
      recipientDeviceId: 'bob-chrome',
      recipientX25519KeyPair: recipientKey ?? bobX,
      trustedEpochStore: floor,
    );
  }
}

void main() {
  test('no unverified key session exists by default', () async {
    final sessions = VerifiedTripProfileSessions();
    await expectLater(
      sessions.requireLease(
        tripId: tripId,
        profileUid: 'alice',
        currentUserUid: 'bob',
      ),
      throwsStateError,
    );
  });

  test('signed roster and rotation unlock the correct key', () async {
    final f = await Fixture.create();
    final sessions = VerifiedTripProfileSessions();
    final epochs = TestEpochs(2);
    await f.unlock(sessions, epochs);
    final lease = await sessions.requireLease(
      tripId: tripId,
      profileUid: 'alice',
      currentUserUid: 'bob',
    );
    final key = await lease.requireKey(
      tripId: tripId,
      profileUid: 'alice',
      currentUserUid: 'bob',
    );
    final opened = await TripTravellerE2eeBridge().openMember(
      transport: f.rotation.encryptedProfile,
      profileKey: key,
      tripId: tripId,
      memberUid: 'alice',
    );
    expect(opened.toMap(), profile.toMap());
  });

  test('cannot reuse lease for another trip, profile or account', () async {
    final f = await Fixture.create();
    final sessions = VerifiedTripProfileSessions();
    await f.unlock(sessions, TestEpochs(2));
    final lease = await sessions.requireLease(
      tripId: tripId,
      profileUid: 'alice',
      currentUserUid: 'bob',
    );
    for (final mismatch in [
      ('wrong-trip', 'alice', 'bob'),
      (tripId, 'different', 'bob'),
      (tripId, 'alice', 'marco'),
    ]) {
      await expectLater(
        lease.requireKey(
          tripId: mismatch.$1,
          profileUid: mismatch.$2,
          currentUserUid: mismatch.$3,
        ),
        throwsStateError,
      );
    }
  });

  test('new trusted epoch invalidates old key lease', () async {
    final f = await Fixture.create();
    final epochs = TestEpochs(2);
    final sessions = VerifiedTripProfileSessions();
    await f.unlock(sessions, epochs);
    epochs.floor = 3;
    await expectLater(
      sessions.requireLease(
        tripId: tripId,
        profileUid: 'alice',
        currentUserUid: 'bob',
      ),
      throwsStateError,
    );
  });

  test('missing trusted epoch blocks unlocking', () async {
    final f = await Fixture.create();
    await expectLater(
      f.unlock(VerifiedTripProfileSessions(), TestEpochs(null)),
      throwsStateError,
    );
  });

  test('failed epoch persistence blocks unlocking', () async {
    final f = await Fixture.create();
    final epochs = TestEpochs(2)..failWrite = true;
    await expectLater(
      f.unlock(VerifiedTripProfileSessions(), epochs),
      throwsStateError,
    );
  });

  test('wrong pinned authority cannot unlock', () async {
    final f = await Fixture.create();
    final attacker = await Ed25519().newKeyPair();
    await expectLater(
      f.unlock(
        VerifiedTripProfileSessions(),
        TestEpochs(2),
        signer: await attacker.extractPublicKey(),
      ),
      throwsStateError,
    );
  });

  test('wrong recipient device cannot unlock', () async {
    final f = await Fixture.create();
    await expectLater(
      f.unlock(
        VerifiedTripProfileSessions(),
        TestEpochs(2),
        recipientKey: await X25519().newKeyPair(),
      ),
      throwsStateError,
    );
  });

  test('trip exit revokes locally cached leases', () async {
    final f = await Fixture.create();
    final sessions = VerifiedTripProfileSessions();
    await f.unlock(sessions, TestEpochs(2));
    sessions.clearTrip(tripId);
    await expectLater(
      sessions.requireLease(
        tripId: tripId,
        profileUid: 'alice',
        currentUserUid: 'bob',
      ),
      throwsStateError,
    );
  });
}
