import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/signed_trip_device_roster.dart';
import 'package:amaterasutrip/core/security/traveller_profile_key_rotation.dart';
import 'package:amaterasutrip/core/security/verified_trip_rotation_reader.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

const _tripId = 'roster-trip';

const _profile = TripTravellerProfileData(
  hasAllergies: true,
  allergies: 'Informazione privata del questionario',
);

class _Fixture {
  _Fixture({
    required this.aliceX,
    required this.bobX,
    required this.marcoX,
    required this.aliceEd,
    required this.aliceEdPublic,
    required this.alice,
    required this.bob,
    required this.marco,
    required this.aliceRecipient,
    required this.bobRecipient,
    required this.marcoRecipient,
    required this.aliceXPin,
  });

  final SimpleKeyPair aliceX;
  final SimpleKeyPair bobX;
  final SimpleKeyPair marcoX;
  final SimpleKeyPair aliceEd;
  final SimplePublicKey aliceEdPublic;

  final RosterDevice alice;
  final RosterDevice bob;
  final RosterDevice marco;

  final ProfileRotationRecipient aliceRecipient;
  final ProfileRotationRecipient bobRecipient;
  final ProfileRotationRecipient marcoRecipient;

  final TrustedDevicePublicKey aliceXPin;

  final SignedTripDeviceRosterVerifier verifier =
      SignedTripDeviceRosterVerifier();

  static Future<_Fixture> create() async {
    final x = X25519();
    final ed = Ed25519();

    final aliceX = await x.newKeyPair();
    final bobX = await x.newKeyPair();
    final marcoX = await x.newKeyPair();

    final aliceEd = await ed.newKeyPair();
    final bobEd = await ed.newKeyPair();
    final marcoEd = await ed.newKeyPair();

    final fingerprint = TrustedDevicePublicKeyVerifier();

    Future<(RosterDevice, ProfileRotationRecipient, TrustedDevicePublicKey)>
    createDevice(
      String uid,
      String deviceId,
      SimpleKeyPair xKey,
      SimpleKeyPair signingKey,
    ) async {
      final xPublic = await xKey.extractPublicKey();
      final edPublic = await signingKey.extractPublicKey();

      final pin = TrustedDevicePublicKey(
        userUid: uid,
        deviceId: deviceId,
        fingerprint: await fingerprint.fingerprint(xPublic.bytes),
      );

      return (
        RosterDevice(
          uid: uid,
          deviceId: deviceId,
          x25519Fingerprint: pin.fingerprint,
          ed25519PublicKeyBytes: edPublic.bytes,
        ),
        ProfileRotationRecipient(
          uid: uid,
          deviceId: deviceId,
          x25519PublicKey: xPublic.bytes,
          trustedPublicKey: pin,
        ),
        pin,
      );
    }

    final a = await createDevice('alice', 'alice-android', aliceX, aliceEd);
    final b = await createDevice('bob', 'bob-chrome', bobX, bobEd);
    final m = await createDevice('marco', 'marco-android', marcoX, marcoEd);

    return _Fixture(
      aliceX: aliceX,
      bobX: bobX,
      marcoX: marcoX,
      aliceEd: aliceEd,
      aliceEdPublic: await aliceEd.extractPublicKey(),
      alice: a.$1,
      bob: b.$1,
      marco: m.$1,
      aliceRecipient: a.$2,
      bobRecipient: b.$2,
      marcoRecipient: m.$2,
      aliceXPin: a.$3,
    );
  }

  Future<SignedTripDeviceRoster> roster({
    List<RosterDevice>? devices,
    Set<String> revoked = const {'marco'},
    int epoch = 2,
  }) {
    return verifier.sign(
      tripId: _tripId,
      authorityUid: 'alice',
      authorityDeviceId: 'alice-android',
      epoch: epoch,
      activeDevices: devices ?? [alice, bob],
      revokedMemberUids: revoked,
      authorityEd25519KeyPair: aliceEd,
    );
  }

  Future<SignedProfileKeyRotation> rotation({
    List<ProfileRotationRecipient>? recipients,
  }) {
    return TravellerProfileKeyRotation().rotate(
      profile: _profile,
      tripId: _tripId,
      profileUid: 'alice',
      senderDeviceId: 'alice-android',
      previousEpoch: 1,
      revokedMemberUids: const {'marco'},
      activeRecipients: recipients ?? [aliceRecipient, bobRecipient],
      senderX25519KeyPair: aliceX,
      senderEd25519KeyPair: aliceEd,
    );
  }

  Future<TripTravellerProfileData> open(
    SignedTripDeviceRoster roster,
    SignedProfileKeyRotation rotation, {
    SimplePublicKey? authorityKey,
    SimpleKeyPair? recipientKey,
    int trustedFloor = 2,
  }) {
    return verifier.openVerifiedRotation(
      roster: roster,
      rotation: rotation,
      expectedTripId: _tripId,
      expectedAuthorityUid: 'alice',
      expectedAuthorityDeviceId: 'alice-android',
      minimumTrustedEpoch: trustedFloor,
      pinnedAuthorityEd25519: authorityKey ?? aliceEdPublic,
      trustedSenderX25519: aliceXPin,
      pinnedSenderEd25519: aliceEdPublic,
      recipientUid: 'bob',
      recipientDeviceId: 'bob-chrome',
      recipientX25519KeyPair: recipientKey ?? bobX,
    );
  }
}

class _TestTrustedEpochStore implements TrustedTripEpochStore {
  _TestTrustedEpochStore(this.floor, {this.rejectWrite = false});

  int? floor;
  final bool rejectWrite;

  @override
  Future<int?> readTrustedFloor(String tripId) async {
    if (tripId != _tripId) {
      throw StateError('Unknown trip trust context.');
    }
    return floor;
  }

  @override
  Future<void> advanceTrustedFloor(String tripId, int verifiedEpoch) async {
    if (tripId != _tripId || rejectWrite) {
      throw StateError('Trusted epoch persistence failed.');
    }

    if (floor == null || verifiedEpoch < floor!) {
      throw StateError('Trusted epoch regression refused.');
    }

    floor = verifiedEpoch;
  }
}

Future<TripTravellerProfileData> _openWithTrustedEpoch(
  _Fixture fixture,
  _TestTrustedEpochStore epochStore,
) async {
  final roster = await fixture.roster();
  final rotation = await fixture.rotation();

  return VerifiedTripRotationReader(epochStore).open(
    roster: roster,
    rotation: rotation,
    tripId: _tripId,
    authorityUid: 'alice',
    authorityDeviceId: 'alice-android',
    pinnedAuthorityEd25519: fixture.aliceEdPublic,
    trustedSenderX25519: fixture.aliceXPin,
    pinnedSenderEd25519: fixture.aliceEdPublic,
    recipientUid: 'bob',
    recipientDeviceId: 'bob-chrome',
    recipientX25519KeyPair: fixture.bobX,
  );
}

void main() {
  test('signed roster permits Bob to open new encrypted data', () async {
    final f = await _Fixture.create();
    final roster = await f.roster();
    final rotation = await f.rotation();

    final opened = await f.open(roster, rotation);

    expect(opened.toMap(), _profile.toMap());
  });

  test('revoked Marco is absent from signed active devices', () async {
    final f = await _Fixture.create();
    final roster = await f.roster();

    expect(roster.revokedMemberUids, contains('marco'));
    expect(roster.activeDevices.any((device) => device.uid == 'marco'), false);
  });

  test('cannot sign a roster that includes revoked Marco', () async {
    final f = await _Fixture.create();

    await expectLater(
      f.roster(devices: [f.alice, f.bob, f.marco]),
      throwsA(isA<StateError>()),
    );
  });

  test('tampering with signed roster invalidates signature', () async {
    final f = await _Fixture.create();
    final signed = await f.roster();

    final altered = SignedTripDeviceRoster(
      tripId: signed.tripId,
      authorityUid: signed.authorityUid,
      authorityDeviceId: signed.authorityDeviceId,
      epoch: signed.epoch,
      activeDevices: [f.alice, f.marco],
      revokedMemberUids: const ['bob'],
      signatureBytes: signed.signatureBytes,
    );

    await expectLater(
      f.open(altered, await f.rotation()),
      throwsA(isA<StateError>()),
    );
  });

  test('untrusted authority signing key is rejected', () async {
    final f = await _Fixture.create();
    final attacker = await Ed25519().newKeyPair();

    await expectLater(
      f.open(
        await f.roster(),
        await f.rotation(),
        authorityKey: await attacker.extractPublicKey(),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('another private key cannot impersonate Bob', () async {
    final f = await _Fixture.create();

    await expectLater(
      f.open(await f.roster(), await f.rotation(), recipientKey: f.marcoX),
      throwsA(isA<StateError>()),
    );
  });

  test('a signed older epoch is rejected', () async {
    final f = await _Fixture.create();

    await expectLater(
      f.open(await f.roster(), await f.rotation(), trustedFloor: 3),
      throwsA(isA<StateError>()),
    );
  });

  test('extra non-revoked grant is rejected by signed roster', () async {
    final f = await _Fixture.create();

    final claraX = await X25519().newKeyPair();
    final claraPublic = await claraX.extractPublicKey();

    final claraPin = TrustedDevicePublicKey(
      userUid: 'clara',
      deviceId: 'clara-chrome',
      fingerprint: await TrustedDevicePublicKeyVerifier().fingerprint(
        claraPublic.bytes,
      ),
    );

    final claraRecipient = ProfileRotationRecipient(
      uid: 'clara',
      deviceId: 'clara-chrome',
      x25519PublicKey: claraPublic.bytes,
      trustedPublicKey: claraPin,
    );

    // A valid signed rotation grants Clara a key, but the separately
    // signed, independently pinned roster contains only Alice and Bob.
    final rotation = await f.rotation(
      recipients: [f.aliceRecipient, f.bobRecipient, claraRecipient],
    );

    final roster = await f.roster();

    expect(
      rotation.grants.any((grant) => grant.recipientUid == 'clara'),
      isTrue,
    );

    await expectLater(f.open(roster, rotation), throwsA(isA<StateError>()));
  });

  test('trusted reader opens profile and records verified epoch', () async {
    final f = await _Fixture.create();
    final store = _TestTrustedEpochStore(2);

    final opened = await _openWithTrustedEpoch(f, store);

    expect(opened.toMap(), _profile.toMap());
    expect(store.floor, 2);
  });

  test('trusted reader refuses an old but valid signed epoch', () async {
    final f = await _Fixture.create();
    final store = _TestTrustedEpochStore(3);

    await expectLater(
      _openWithTrustedEpoch(f, store),
      throwsA(isA<StateError>()),
    );

    expect(store.floor, 3);
  });

  test('trusted reader refuses missing trust bootstrap', () async {
    final f = await _Fixture.create();
    final store = _TestTrustedEpochStore(null);

    await expectLater(
      _openWithTrustedEpoch(f, store),
      throwsA(isA<StateError>()),
    );

    expect(store.floor, isNull);
  });

  test('trusted reader refuses failed epoch persistence', () async {
    final f = await _Fixture.create();
    final store = _TestTrustedEpochStore(2, rejectWrite: true);

    await expectLater(
      _openWithTrustedEpoch(f, store),
      throwsA(isA<StateError>()),
    );

    expect(store.floor, 2);
  });
  test('duplicate device identity cannot be signed', () async {
    final f = await _Fixture.create();

    await expectLater(
      f.roster(devices: [f.alice, f.bob, f.bob]),
      throwsA(isA<StateError>()),
    );
  });

  test('authority itself must remain in the roster', () async {
    final f = await _Fixture.create();

    await expectLater(f.roster(devices: [f.bob]), throwsA(isA<StateError>()));
  });
}
