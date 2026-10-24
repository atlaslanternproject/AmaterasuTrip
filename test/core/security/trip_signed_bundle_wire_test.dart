import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/authenticated_profile_key_exchange.dart';
import 'package:amaterasutrip/core/security/signed_trip_device_roster.dart';
import 'package:amaterasutrip/core/security/traveller_profile_key_rotation.dart';
import 'package:amaterasutrip/core/security/traveller_profile_key_wrap.dart';
import 'package:amaterasutrip/core/security/trip_signed_bundle_wire.dart';

class Fixture {
  Fixture(this.roster, this.rotation, this.publicKey);

  final SignedTripDeviceRoster roster;
  final SignedProfileKeyRotation rotation;
  final SimplePublicKey publicKey;
}

Future<Fixture> fixture() async {
  final ed = Ed25519();
  final signer = await ed.newKeyPair();
  final publicKey = await signer.extractPublicKey();

  final rosterUnsigned = SignedTripDeviceRoster(
    tripId: 'trip-a',
    authorityUid: 'alice',
    authorityDeviceId: 'device-a',
    epoch: 2,
    activeDevices: [
      RosterDevice(
        uid: 'alice',
        deviceId: 'device-a',
        x25519Fingerprint: 'alice-pin',
        ed25519PublicKeyBytes: publicKey.bytes,
      ),
      RosterDevice(
        uid: 'bob',
        deviceId: 'device-b',
        x25519Fingerprint: 'bob-pin',
        ed25519PublicKeyBytes: List<int>.filled(32, 7),
      ),
    ],
    revokedMemberUids: ['marco'],
    signatureBytes: const [],
  );

  final rosterSignature = await ed.sign(
    rosterUnsigned.signingBytes,
    keyPair: signer,
  );

  final roster = rosterUnsigned.withSignature(rosterSignature.bytes);

  final wrapped = WrappedTravellerProfileKey(
    salt: base64Encode(List<int>.filled(32, 11)),
    nonce: base64Encode(List<int>.filled(12, 12)),
    ciphertext: base64Encode(List<int>.filled(32, 13)),
    mac: base64Encode(List<int>.filled(16, 14)),
  );

  Future<SignedTravellerProfileKeyGrant> grant(
    String uid,
    String deviceId,
  ) async {
    final unsigned = SignedTravellerProfileKeyGrant(
      tripId: 'trip-a',
      profileUid: 'alice',
      senderUid: 'alice',
      recipientUid: uid,
      senderDeviceId: 'device-a',
      recipientDeviceId: deviceId,
      keyEpoch: 2,
      senderX25519PublicKey: List<int>.filled(32, 2),
      recipientX25519PublicKey: List<int>.filled(32, 3),
      wrappedKey: wrapped,
      signatureBytes: const [],
    );

    final signature = await ed.sign(unsigned.signingBytes, keyPair: signer);

    return unsigned.withSignature(signature.bytes);
  }

  final grants = [
    await grant('alice', 'device-a'),
    await grant('bob', 'device-b'),
  ];

  final rotationUnsigned = SignedProfileKeyRotation(
    tripId: 'trip-a',
    profileUid: 'alice',
    senderDeviceId: 'device-a',
    epoch: 2,
    encryptedProfile: {
      'hasEsimOrInternet': null,
      'hasCheckedBaggage': true,
      'hasCabinBaggage10Kg': null,
      'protectedDetails': {
        'version': 1,
        'algorithm': 'AES-256-GCM',
        'nonce': base64Encode(List<int>.filled(12, 5)),
        'ciphertext': base64Encode(List<int>.filled(96, 6)),
        'mac': base64Encode(List<int>.filled(16, 7)),
      },
    },
    grants: grants,
    revokedMemberUids: ['marco'],
    signatureBytes: const [],
  );

  final signature = await ed.sign(
    rotationUnsigned.signingBytes,
    keyPair: signer,
  );

  return Fixture(
    roster,
    rotationUnsigned.withSignature(signature.bytes),
    publicKey,
  );
}

void main() {
  test('All three signature layers survive the wire roundtrip', () async {
    final data = await fixture();

    final encoded = TripSignedBundleWire.encode(
      roster: data.roster,
      rotation: data.rotation,
    );

    final decoded = TripSignedBundleWire.decodeUntrusted(encoded);
    final ed = Ed25519();

    expect(decoded.roster.signingBytes, data.roster.signingBytes);
    expect(decoded.rotation.signingBytes, data.rotation.signingBytes);
    expect(decoded.rotation.grants, hasLength(2));

    Future<bool> authentic(List<int> bytes, List<int> signature) {
      return ed.verify(
        bytes,
        signature: Signature(signature, publicKey: data.publicKey),
      );
    }

    expect(
      await authentic(
        decoded.roster.signingBytes,
        decoded.roster.signatureBytes,
      ),
      isTrue,
    );

    expect(
      await authentic(
        decoded.rotation.signingBytes,
        decoded.rotation.signatureBytes,
      ),
      isTrue,
    );

    for (final grant in decoded.rotation.grants) {
      expect(await authentic(grant.signingBytes, grant.signatureBytes), isTrue);
    }
  });

  test('Plaintext health field in wire is rejected', () async {
    final data = await fixture();
    final wire = TripSignedBundleWire.encode(
      roster: data.roster,
      rotation: data.rotation,
    );

    final rotation = wire['rotation'] as Map<String, dynamic>;
    final profile = rotation['encryptedProfile'] as Map<String, dynamic>;
    profile['allergies'] = 'plaintext-not-allowed';

    expect(
      () => TripSignedBundleWire.decodeUntrusted(wire),
      throwsFormatException,
    );
  });

  test('Inconsistent roster epoch is rejected', () async {
    final data = await fixture();
    final wire = TripSignedBundleWire.encode(
      roster: data.roster,
      rotation: data.rotation,
    );

    final roster = wire['roster'] as Map<String, dynamic>;
    roster['epoch'] = 3;

    expect(
      () => TripSignedBundleWire.decodeUntrusted(wire),
      throwsFormatException,
    );
  });

  test('Unknown fields are rejected', () async {
    final data = await fixture();
    final wire = TripSignedBundleWire.encode(
      roster: data.roster,
      rotation: data.rotation,
    );

    wire['privateKey'] = 'forbidden';

    expect(
      () => TripSignedBundleWire.decodeUntrusted(wire),
      throwsFormatException,
    );
  });

  test('Tampering with a grant does not authenticate it', () async {
    final data = await fixture();
    final wire = TripSignedBundleWire.encode(
      roster: data.roster,
      rotation: data.rotation,
    );

    final rotation = wire['rotation'] as Map<String, dynamic>;
    final grants = rotation['grants'] as List<dynamic>;
    final first = grants.first as Map<String, dynamic>;

    first['signature'] = base64Encode(List<int>.filled(64, 44));

    final decoded = TripSignedBundleWire.decodeUntrusted(wire);
    final grant = decoded.rotation.grants.first;

    final valid = await Ed25519().verify(
      grant.signingBytes,
      signature: Signature(grant.signatureBytes, publicKey: data.publicKey),
    );

    expect(valid, isFalse);
  });
}
