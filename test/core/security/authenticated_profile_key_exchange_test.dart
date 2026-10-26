import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/authenticated_profile_key_exchange.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';

class Fixture {
  Fixture({
    required this.service,
    required this.senderX,
    required this.recipientX,
    required this.senderSigning,
    required this.senderSigningPublic,
    required this.recipientPublic,
    required this.profileKey,
    required this.senderPin,
    required this.recipientPin,
  });

  final AuthenticatedProfileKeyExchange service;
  final SimpleKeyPair senderX;
  final SimpleKeyPair recipientX;
  final SimpleKeyPair senderSigning;
  final SimplePublicKey senderSigningPublic;
  final SimplePublicKey recipientPublic;
  final SecretKey profileKey;
  final TrustedDevicePublicKey senderPin;
  final TrustedDevicePublicKey recipientPin;
}

Future<Fixture> fixture() async {
  final x25519 = X25519();
  final ed25519 = Ed25519();
  final pins = TrustedDevicePublicKeyVerifier();

  final senderX = await x25519.newKeyPair();
  final recipientX = await x25519.newKeyPair();
  final senderSigning = await ed25519.newKeyPair();

  final senderPublic = await senderX.extractPublicKey();
  final recipientPublic = await recipientX.extractPublicKey();

  return Fixture(
    service: AuthenticatedProfileKeyExchange(),
    senderX: senderX,
    recipientX: recipientX,
    senderSigning: senderSigning,
    senderSigningPublic: await senderSigning.extractPublicKey(),
    recipientPublic: recipientPublic,
    profileKey: await AesGcm.with256bits().newSecretKey(),
    senderPin: TrustedDevicePublicKey(
      userUid: 'alice',
      deviceId: 'alice-android',
      fingerprint: await pins.fingerprint(senderPublic.bytes),
    ),
    recipientPin: TrustedDevicePublicKey(
      userUid: 'bob',
      deviceId: 'bob-chrome',
      fingerprint: await pins.fingerprint(recipientPublic.bytes),
    ),
  );
}

Future<SignedTravellerProfileKeyGrant> issue(
  Fixture f, {
  TrustedDevicePublicKey? recipientPin,
  List<int>? recipientPublic,
}) {
  return f.service.issue(
    tripId: 'trip-1',
    profileUid: 'alice',
    senderUid: 'alice',
    recipientUid: 'bob',
    senderDeviceId: 'alice-android',
    recipientDeviceId: 'bob-chrome',
    keyEpoch: 1,
    profileKey: f.profileKey,
    senderX25519KeyPair: f.senderX,
    senderEd25519KeyPair: f.senderSigning,
    recipientX25519PublicKey: recipientPublic ?? f.recipientPublic.bytes,
    trustedRecipient: recipientPin ?? f.recipientPin,
  );
}

Future<SecretKey> receive(
  Fixture f,
  SignedTravellerProfileKeyGrant grant, {
  TrustedDevicePublicKey? senderPin,
  SimplePublicKey? senderSigningPublic,
  SimpleKeyPair? recipientPrivate,
  int epoch = 1,
}) {
  return f.service.receive(
    grant: grant,
    expectedTripId: 'trip-1',
    expectedProfileUid: 'alice',
    expectedSenderUid: 'alice',
    expectedRecipientUid: 'bob',
    expectedSenderDeviceId: 'alice-android',
    expectedRecipientDeviceId: 'bob-chrome',
    expectedKeyEpoch: epoch,
    trustedSenderX25519: senderPin ?? f.senderPin,
    pinnedSenderEd25519: senderSigningPublic ?? f.senderSigningPublic,
    recipientX25519KeyPair: recipientPrivate ?? f.recipientX,
  );
}

void main() {
  test('two independently pinned devices exchange a profile key', () async {
    final f = await fixture();
    final grant = await issue(f);
    final restored = await receive(f, grant);

    expect(await restored.extractBytes(), await f.profileKey.extractBytes());
  });

  test('sender refuses substituted recipient X25519 key', () async {
    final f = await fixture();
    final attacker = await X25519().newKeyPair();
    final attackerPublic = await attacker.extractPublicKey();

    await expectLater(
      issue(f, recipientPublic: attackerPublic.bytes),
      throwsA(isA<StateError>()),
    );
  });

  test('recipient refuses substituted sender X25519 trust pin', () async {
    final f = await fixture();
    final grant = await issue(f);

    final wrongPin = TrustedDevicePublicKey(
      userUid: 'alice',
      deviceId: 'alice-android',
      fingerprint: 'not-the-real-fingerprint',
    );

    await expectLater(
      receive(f, grant, senderPin: wrongPin),
      throwsA(isA<StateError>()),
    );
  });

  test('recipient refuses substituted Ed25519 signing identity', () async {
    final f = await fixture();
    final grant = await issue(f);
    final attacker = await Ed25519().newKeyPair();

    await expectLater(
      receive(f, grant, senderSigningPublic: await attacker.extractPublicKey()),
      throwsA(isA<StateError>()),
    );
  });

  test('a different recipient private key cannot receive', () async {
    final f = await fixture();
    final grant = await issue(f);
    final otherDevice = await X25519().newKeyPair();

    await expectLater(
      receive(f, grant, recipientPrivate: otherDevice),
      throwsA(isA<StateError>()),
    );
  });

  test('outdated key epoch is rejected', () async {
    final f = await fixture();
    final grant = await issue(f);

    await expectLater(receive(f, grant, epoch: 2), throwsA(isA<StateError>()));
  });

  test('tampered Ed25519 signature is rejected', () async {
    final f = await fixture();
    final grant = await issue(f);

    final altered = grant.withSignature(List<int>.filled(64, 0));

    await expectLater(receive(f, altered), throwsA(isA<StateError>()));
  });
}
