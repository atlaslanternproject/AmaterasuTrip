import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'traveller_profile_key_wrap.dart';
import 'trusted_device_public_key.dart';

/// Experimental signed transfer of a traveller profile key.
///
/// No Firebase calls, key persistence, membership verification,
/// recovery or revocation handling are implemented here.
///
/// The sender and recipient trust pins MUST come from independently
/// authenticated sources. This module must not grant access by itself.
class SignedTravellerProfileKeyGrant {
  SignedTravellerProfileKeyGrant({
    required this.tripId,
    required this.profileUid,
    required this.senderUid,
    required this.recipientUid,
    required this.senderDeviceId,
    required this.recipientDeviceId,
    required this.keyEpoch,
    required List<int> senderX25519PublicKey,
    required List<int> recipientX25519PublicKey,
    required this.wrappedKey,
    required List<int> signatureBytes,
  }) : senderX25519PublicKey = List<int>.unmodifiable(senderX25519PublicKey),
       recipientX25519PublicKey = List<int>.unmodifiable(
         recipientX25519PublicKey,
       ),
       signatureBytes = List<int>.unmodifiable(signatureBytes);

  final String tripId;
  final String profileUid;
  final String senderUid;
  final String recipientUid;
  final String senderDeviceId;
  final String recipientDeviceId;
  final int keyEpoch;

  final List<int> senderX25519PublicKey;
  final List<int> recipientX25519PublicKey;
  final WrappedTravellerProfileKey wrappedKey;
  final List<int> signatureBytes;

  /// Domain-separated, deterministic signing representation.
  List<int> get signingBytes => utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'signed-traveller-profile-key-grant',
      1,
      tripId,
      profileUid,
      senderUid,
      recipientUid,
      senderDeviceId,
      recipientDeviceId,
      keyEpoch,
      base64Encode(senderX25519PublicKey),
      base64Encode(recipientX25519PublicKey),
      wrappedKey.salt,
      wrappedKey.nonce,
      wrappedKey.ciphertext,
      wrappedKey.mac,
    ]),
  );

  SignedTravellerProfileKeyGrant withSignature(List<int> signature) {
    return SignedTravellerProfileKeyGrant(
      tripId: tripId,
      profileUid: profileUid,
      senderUid: senderUid,
      recipientUid: recipientUid,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipientDeviceId,
      keyEpoch: keyEpoch,
      senderX25519PublicKey: senderX25519PublicKey,
      recipientX25519PublicKey: recipientX25519PublicKey,
      wrappedKey: wrappedKey,
      signatureBytes: signature,
    );
  }
}

class AuthenticatedProfileKeyExchange {
  final X25519 _exchange = X25519();
  final Ed25519 _signatures = Ed25519();
  final TravellerProfileKeyWrap _wrap = TravellerProfileKeyWrap();
  final TrustedDevicePublicKeyVerifier _pins = TrustedDevicePublicKeyVerifier();

  Future<SignedTravellerProfileKeyGrant> issue({
    required String tripId,
    required String profileUid,
    required String senderUid,
    required String recipientUid,
    required String senderDeviceId,
    required String recipientDeviceId,
    required int keyEpoch,
    required SecretKey profileKey,
    required SimpleKeyPair senderX25519KeyPair,
    required SimpleKeyPair senderEd25519KeyPair,
    required List<int> recipientX25519PublicKey,
    required TrustedDevicePublicKey trustedRecipient,
  }) async {
    _validateContext([
      tripId,
      profileUid,
      senderUid,
      recipientUid,
      senderDeviceId,
      recipientDeviceId,
    ], keyEpoch);

    // A Firebase-provided fingerprint is not an independent trust pin.
    await _pins.requireTrusted(
      trusted: trustedRecipient,
      userUid: recipientUid,
      deviceId: recipientDeviceId,
      presentedPublicKey: recipientX25519PublicKey,
    );

    final senderPublicKey = await senderX25519KeyPair.extractPublicKey();

    final signingPublicKey = await senderEd25519KeyPair.extractPublicKey();

    if (senderPublicKey.type != KeyPairType.x25519 ||
        signingPublicKey.type != KeyPairType.ed25519) {
      throw StateError('Invalid sender key types.');
    }

    final shared = await _exchange.sharedSecretKey(
      keyPair: senderX25519KeyPair,
      remotePublicKey: SimplePublicKey(
        recipientX25519PublicKey,
        type: KeyPairType.x25519,
      ),
    );

    final wrapped = await _wrap.wrap(
      sharedSecret: await shared.extractBytes(),
      profileKey: await profileKey.extractBytes(),
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipientDeviceId,
    );

    final unsigned = SignedTravellerProfileKeyGrant(
      tripId: tripId,
      profileUid: profileUid,
      senderUid: senderUid,
      recipientUid: recipientUid,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipientDeviceId,
      keyEpoch: keyEpoch,
      senderX25519PublicKey: senderPublicKey.bytes,
      recipientX25519PublicKey: recipientX25519PublicKey,
      wrappedKey: wrapped,
      signatureBytes: const [],
    );

    final signature = await _signatures.sign(
      unsigned.signingBytes,
      keyPair: senderEd25519KeyPair,
    );

    return unsigned.withSignature(signature.bytes);
  }

  Future<SecretKey> receive({
    required SignedTravellerProfileKeyGrant grant,
    required String expectedTripId,
    required String expectedProfileUid,
    required String expectedSenderUid,
    required String expectedRecipientUid,
    required String expectedSenderDeviceId,
    required String expectedRecipientDeviceId,
    required int expectedKeyEpoch,
    required TrustedDevicePublicKey trustedSenderX25519,
    required SimplePublicKey pinnedSenderEd25519,
    required SimpleKeyPair recipientX25519KeyPair,
  }) async {
    _validateContext([
      expectedTripId,
      expectedProfileUid,
      expectedSenderUid,
      expectedRecipientUid,
      expectedSenderDeviceId,
      expectedRecipientDeviceId,
    ], expectedKeyEpoch);

    if (grant.tripId != expectedTripId ||
        grant.profileUid != expectedProfileUid ||
        grant.senderUid != expectedSenderUid ||
        grant.recipientUid != expectedRecipientUid ||
        grant.senderDeviceId != expectedSenderDeviceId ||
        grant.recipientDeviceId != expectedRecipientDeviceId ||
        grant.keyEpoch != expectedKeyEpoch) {
      throw StateError('Signed key grant context mismatch.');
    }

    if (pinnedSenderEd25519.type != KeyPairType.ed25519 ||
        pinnedSenderEd25519.bytes.length != 32 ||
        grant.signatureBytes.length != 64) {
      throw StateError('Invalid sender signing identity.');
    }

    await _pins.requireTrusted(
      trusted: trustedSenderX25519,
      userUid: expectedSenderUid,
      deviceId: expectedSenderDeviceId,
      presentedPublicKey: grant.senderX25519PublicKey,
    );

    final localPublicKey = await recipientX25519KeyPair.extractPublicKey();

    if (localPublicKey.type != KeyPairType.x25519 ||
        !_sameBytes(localPublicKey.bytes, grant.recipientX25519PublicKey)) {
      throw StateError('Key grant targets a different device.');
    }

    final validSignature = await _signatures.verify(
      grant.signingBytes,
      signature: Signature(
        grant.signatureBytes,
        publicKey: pinnedSenderEd25519,
      ),
    );

    if (!validSignature) {
      throw StateError('Invalid signed profile key grant.');
    }

    final shared = await _exchange.sharedSecretKey(
      keyPair: recipientX25519KeyPair,
      remotePublicKey: SimplePublicKey(
        grant.senderX25519PublicKey,
        type: KeyPairType.x25519,
      ),
    );

    final profileKeyBytes = await _wrap.unwrap(
      envelope: grant.wrappedKey,
      sharedSecret: await shared.extractBytes(),
      tripId: grant.tripId,
      profileUid: grant.profileUid,
      senderDeviceId: grant.senderDeviceId,
      recipientDeviceId: grant.recipientDeviceId,
    );

    return SecretKey(profileKeyBytes);
  }

  void _validateContext(List<String> values, int epoch) {
    if (epoch <= 0 ||
        values.any(
          (value) =>
              value.trim().isEmpty ||
              value.length > 1024 ||
              value.codeUnits.any((unit) => unit < 32),
        )) {
      throw ArgumentError('Invalid key grant context.');
    }
  }

  bool _sameBytes(List<int> first, List<int> second) {
    if (first.length != second.length) return false;

    var difference = 0;

    for (var i = 0; i < first.length; i++) {
      difference |= first[i] ^ second[i];
    }

    return difference == 0;
  }
}
