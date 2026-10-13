import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'traveller_profile_key_rotation.dart';
import 'trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

class RosterDevice {
  RosterDevice({
    required this.uid,
    required this.deviceId,
    required this.x25519Fingerprint,
    required List<int> ed25519PublicKeyBytes,
  }) : ed25519PublicKeyBytes = List<int>.unmodifiable(ed25519PublicKeyBytes);

  final String uid;
  final String deviceId;
  final String x25519Fingerprint;
  final List<int> ed25519PublicKeyBytes;

  String get identity => jsonEncode([uid, deviceId]);

  List<Object> get signedFields => [
    uid,
    deviceId,
    x25519Fingerprint,
    base64Encode(ed25519PublicKeyBytes),
  ];
}

/// Signed and canonical membership snapshot.
///
/// It establishes trust only when the authority signing key has
/// already been independently pinned by the receiving device.
class SignedTripDeviceRoster {
  SignedTripDeviceRoster({
    required this.tripId,
    required this.authorityUid,
    required this.authorityDeviceId,
    required this.epoch,
    required List<RosterDevice> activeDevices,
    required List<String> revokedMemberUids,
    required List<int> signatureBytes,
  }) : activeDevices = List<RosterDevice>.unmodifiable(activeDevices),
       revokedMemberUids = List<String>.unmodifiable(revokedMemberUids),
       signatureBytes = List<int>.unmodifiable(signatureBytes);

  final String tripId;
  final String authorityUid;
  final String authorityDeviceId;
  final int epoch;
  final List<RosterDevice> activeDevices;
  final List<String> revokedMemberUids;
  final List<int> signatureBytes;

  List<int> get signingBytes => utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'signed-trip-device-roster',
      1,
      tripId,
      authorityUid,
      authorityDeviceId,
      epoch,
      [for (final device in activeDevices) device.signedFields],
      revokedMemberUids,
    ]),
  );

  SignedTripDeviceRoster withSignature(List<int> signature) {
    return SignedTripDeviceRoster(
      tripId: tripId,
      authorityUid: authorityUid,
      authorityDeviceId: authorityDeviceId,
      epoch: epoch,
      activeDevices: activeDevices,
      revokedMemberUids: revokedMemberUids,
      signatureBytes: signature,
    );
  }
}

/// Isolated verifier for the signed membership roster and key rotations.
///
/// Does not read Firebase, establish first-device trust, persist epochs,
/// or perform live membership revocation.
class SignedTripDeviceRosterVerifier {
  final Ed25519 _ed = Ed25519();

  Future<SignedTripDeviceRoster> sign({
    required String tripId,
    required String authorityUid,
    required String authorityDeviceId,
    required int epoch,
    required List<RosterDevice> activeDevices,
    required Set<String> revokedMemberUids,
    required SimpleKeyPair authorityEd25519KeyPair,
  }) async {
    final sortedDevices = [...activeDevices]
      ..sort((a, b) => a.identity.compareTo(b.identity));

    final sortedRevoked = revokedMemberUids.toList()..sort();

    final unsigned = SignedTripDeviceRoster(
      tripId: tripId,
      authorityUid: authorityUid,
      authorityDeviceId: authorityDeviceId,
      epoch: epoch,
      activeDevices: sortedDevices,
      revokedMemberUids: sortedRevoked,
      signatureBytes: const [],
    );

    _validateStructure(unsigned);

    final issuer = _findDevice(unsigned, authorityUid, authorityDeviceId);

    final publicKey = await authorityEd25519KeyPair.extractPublicKey();

    if (!_sameBytes(issuer.ed25519PublicKeyBytes, publicKey.bytes)) {
      throw StateError('Authority signing key does not match roster.');
    }

    final signature = await _ed.sign(
      unsigned.signingBytes,
      keyPair: authorityEd25519KeyPair,
    );

    return unsigned.withSignature(signature.bytes);
  }

  Future<void> verify({
    required SignedTripDeviceRoster roster,
    required String expectedTripId,
    required String expectedAuthorityUid,
    required String expectedAuthorityDeviceId,
    required int minimumTrustedEpoch,
    required SimplePublicKey pinnedAuthorityEd25519,
  }) async {
    _validateStructure(roster);

    if (roster.tripId != expectedTripId ||
        roster.authorityUid != expectedAuthorityUid ||
        roster.authorityDeviceId != expectedAuthorityDeviceId ||
        roster.epoch < minimumTrustedEpoch ||
        pinnedAuthorityEd25519.type != KeyPairType.ed25519 ||
        roster.signatureBytes.length != 64) {
      throw StateError('Untrusted or outdated device roster.');
    }

    final issuer = _findDevice(
      roster,
      expectedAuthorityUid,
      expectedAuthorityDeviceId,
    );

    if (!_sameBytes(
      issuer.ed25519PublicKeyBytes,
      pinnedAuthorityEd25519.bytes,
    )) {
      throw StateError('Roster authority identity mismatch.');
    }

    final valid = await _ed.verify(
      roster.signingBytes,
      signature: Signature(
        roster.signatureBytes,
        publicKey: pinnedAuthorityEd25519,
      ),
    );

    if (!valid) {
      throw StateError('Invalid roster signature.');
    }
  }

  Future<TripTravellerProfileData> openVerifiedRotation({
    required SignedTripDeviceRoster roster,
    required SignedProfileKeyRotation rotation,
    required String expectedTripId,
    required String expectedAuthorityUid,
    required String expectedAuthorityDeviceId,
    required int minimumTrustedEpoch,
    required SimplePublicKey pinnedAuthorityEd25519,
    required TrustedDevicePublicKey trustedSenderX25519,
    required SimplePublicKey pinnedSenderEd25519,
    required String recipientUid,
    required String recipientDeviceId,
    required SimpleKeyPair recipientX25519KeyPair,
  }) async {
    await verify(
      roster: roster,
      expectedTripId: expectedTripId,
      expectedAuthorityUid: expectedAuthorityUid,
      expectedAuthorityDeviceId: expectedAuthorityDeviceId,
      minimumTrustedEpoch: minimumTrustedEpoch,
      pinnedAuthorityEd25519: pinnedAuthorityEd25519,
    );

    if (rotation.tripId != roster.tripId ||
        rotation.epoch != roster.epoch ||
        rotation.epoch < minimumTrustedEpoch ||
        !_sameStrings(rotation.revokedMemberUids, roster.revokedMemberUids)) {
      throw StateError('Rotation does not match signed membership.');
    }

    final sender = _findDevice(
      roster,
      rotation.profileUid,
      rotation.senderDeviceId,
    );

    final recipient = _findDevice(roster, recipientUid, recipientDeviceId);

    if (!_sameBytes(sender.ed25519PublicKeyBytes, pinnedSenderEd25519.bytes)) {
      throw StateError('Untrusted profile signer.');
    }

    if (trustedSenderX25519.userUid != sender.uid ||
        trustedSenderX25519.deviceId != sender.deviceId ||
        trustedSenderX25519.fingerprint != sender.x25519Fingerprint) {
      throw StateError('Untrusted profile sender device.');
    }

    final recipientPublic = await recipientX25519KeyPair.extractPublicKey();

    final recipientFingerprint = await TrustedDevicePublicKeyVerifier()
        .fingerprint(recipientPublic.bytes);

    if (recipientFingerprint != recipient.x25519Fingerprint) {
      throw StateError('Recipient private key does not match roster.');
    }

    final expectedIdentities = {
      for (final device in roster.activeDevices) device.identity,
    };

    final grantedIdentities = {
      for (final grant in rotation.grants)
        jsonEncode([grant.recipientUid, grant.recipientDeviceId]),
    };

    if (grantedIdentities.length != rotation.grants.length ||
        expectedIdentities.length != grantedIdentities.length ||
        !expectedIdentities.containsAll(grantedIdentities) ||
        !grantedIdentities.containsAll(expectedIdentities)) {
      throw StateError('Rotation grant list differs from signed roster.');
    }

    return TravellerProfileKeyRotation().openForRecipient(
      rotation: rotation,
      expectedTripId: expectedTripId,
      expectedProfileUid: rotation.profileUid,
      expectedSenderDeviceId: rotation.senderDeviceId,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      minimumTrustedEpoch: minimumTrustedEpoch,
      trustedSenderX25519: trustedSenderX25519,
      pinnedSenderEd25519: pinnedSenderEd25519,
      recipientX25519KeyPair: recipientX25519KeyPair,
    );
  }

  void _validateStructure(SignedTripDeviceRoster roster) {
    if (roster.tripId.trim().isEmpty ||
        roster.authorityUid.trim().isEmpty ||
        roster.authorityDeviceId.trim().isEmpty ||
        roster.epoch < 2 ||
        roster.epoch >= 2147483647 ||
        roster.activeDevices.isEmpty ||
        roster.revokedMemberUids.isEmpty) {
      throw StateError('Invalid signed roster.');
    }

    final identities = <String>{};
    var previousIdentity = '';

    for (final device in roster.activeDevices) {
      if (device.uid.trim().isEmpty ||
          device.deviceId.trim().isEmpty ||
          device.x25519Fingerprint.trim().isEmpty ||
          device.ed25519PublicKeyBytes.length != 32 ||
          !identities.add(device.identity) ||
          (previousIdentity.isNotEmpty &&
              previousIdentity.compareTo(device.identity) >= 0) ||
          roster.revokedMemberUids.contains(device.uid)) {
        throw StateError('Invalid or unsorted active device.');
      }

      previousIdentity = device.identity;
    }

    var previousRevoked = '';

    for (final uid in roster.revokedMemberUids) {
      if (uid.trim().isEmpty ||
          (previousRevoked.isNotEmpty && previousRevoked.compareTo(uid) >= 0)) {
        throw StateError('Invalid or unsorted revoked identities.');
      }

      previousRevoked = uid;
    }

    _findDevice(roster, roster.authorityUid, roster.authorityDeviceId);
  }

  RosterDevice _findDevice(
    SignedTripDeviceRoster roster,
    String uid,
    String deviceId,
  ) {
    final matches = roster.activeDevices.where(
      (device) => device.uid == uid && device.deviceId == deviceId,
    );

    if (matches.length != 1) {
      throw StateError('Device is not authorised in signed roster.');
    }

    return matches.single;
  }

  bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
