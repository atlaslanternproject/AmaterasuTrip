import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/trip_profile_access_proof.dart';

void main() {
  test('Authentic local signature verifies', () async {
    final pair = await Ed25519().newKeyPair();
    final publicKey = await pair.extractPublicKey();

    final proof = await TripProfileAccessProofSigner().sign(
      uid: 'bob',
      tripId: 'trip-a',
      profileUid: 'alice',
      deviceId: 'device-b',
      signingKey: pair,
    );

    final signature = Signature(
      base64Decode(proof['signature'] as String),
      publicKey: publicKey,
    );

    final valid = await Ed25519().verify(
      TripProfileAccessProofSigner.signingBytes(proof),
      signature: signature,
    );

    expect(valid, isTrue);
    expect(proof['nonce'], hasLength(43));
    expect(
      (proof['expiresAtMs'] as int) - (proof['issuedAtMs'] as int),
      120000,
    );
    expect(proof.containsKey('privateKey'), isFalse);
  });

  test('Changed profile invalidates signature', () async {
    final pair = await Ed25519().newKeyPair();
    final publicKey = await pair.extractPublicKey();

    final proof = await TripProfileAccessProofSigner().sign(
      uid: 'bob',
      tripId: 'trip-a',
      profileUid: 'alice',
      deviceId: 'device-b',
      signingKey: pair,
    );

    final signature = Signature(
      base64Decode(proof['signature'] as String),
      publicKey: publicKey,
    );

    proof['profileUid'] = 'charlie';

    expect(
      await Ed25519().verify(
        TripProfileAccessProofSigner.signingBytes(proof),
        signature: signature,
      ),
      isFalse,
    );
  });

  test('Nonces differ across requests', () async {
    final pair = await Ed25519().newKeyPair();
    final signer = TripProfileAccessProofSigner();

    Future<Map<String, dynamic>> issue() => signer.sign(
      uid: 'bob',
      tripId: 'trip-a',
      profileUid: 'alice',
      deviceId: 'device-b',
      signingKey: pair,
    );

    final a = await issue();
    final b = await issue();

    expect(a['nonce'], isNot(b['nonce']));
  });

  test('Own-profile request fails', () async {
    final pair = await Ed25519().newKeyPair();

    await expectLater(
      TripProfileAccessProofSigner().sign(
        uid: 'alice',
        tripId: 'trip-a',
        profileUid: 'alice',
        deviceId: 'device-a',
        signingKey: pair,
      ),
      throwsStateError,
    );
  });
}
