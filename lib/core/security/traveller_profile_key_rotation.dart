import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'authenticated_profile_key_exchange.dart';
import 'trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

dynamic _canonical(dynamic value) {
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid encrypted document keys.');
    }

    final keys = value.keys.cast<String>().toList()..sort();

    return {for (final key in keys) key: _canonical(value[key])};
  }

  if (value is List) {
    return value.map(_canonical).toList();
  }

  if (value == null || value is String || value is bool || value is num) {
    return value;
  }

  throw const FormatException('Invalid encrypted document value.');
}

/// Recipient whose public key was independently authenticated.
///
/// Firebase membership information alone does not establish this trust.
class ProfileRotationRecipient {
  ProfileRotationRecipient({
    required this.uid,
    required this.deviceId,
    required List<int> x25519PublicKey,
    required this.trustedPublicKey,
  }) : x25519PublicKey = List<int>.unmodifiable(x25519PublicKey);

  final String uid;
  final String deviceId;
  final List<int> x25519PublicKey;
  final TrustedDevicePublicKey trustedPublicKey;
}

/// Signed, encrypted rotation bundle.
///
/// This is an experimental local protocol. It does not consult Firebase,
/// persist a monotonic epoch, or independently validate trip membership.
class SignedProfileKeyRotation {
  SignedProfileKeyRotation({
    required this.tripId,
    required this.profileUid,
    required this.senderDeviceId,
    required this.epoch,
    required Map<String, dynamic> encryptedProfile,
    required List<SignedTravellerProfileKeyGrant> grants,
    required List<String> revokedMemberUids,
    required List<int> signatureBytes,
  }) : encryptedProfile = Map<String, dynamic>.unmodifiable(encryptedProfile),
       grants = List<SignedTravellerProfileKeyGrant>.unmodifiable(grants),
       revokedMemberUids = List<String>.unmodifiable(revokedMemberUids),
       signatureBytes = List<int>.unmodifiable(signatureBytes);

  final String tripId;
  final String profileUid;
  final String senderDeviceId;
  final int epoch;

  final Map<String, dynamic> encryptedProfile;
  final List<SignedTravellerProfileKeyGrant> grants;
  final List<String> revokedMemberUids;
  final List<int> signatureBytes;

  List<int> get signingBytes => utf8.encode(
    jsonEncode([
      'amaterasutrip',
      'signed-profile-key-rotation',
      1,
      tripId,
      profileUid,
      senderDeviceId,
      epoch,
      jsonEncode(_canonical(encryptedProfile)),
      revokedMemberUids,
      [
        for (final grant in grants)
          [
            base64Encode(grant.signingBytes),
            base64Encode(grant.signatureBytes),
          ],
      ],
    ]),
  );

  SignedProfileKeyRotation withSignature(List<int> signature) {
    return SignedProfileKeyRotation(
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDeviceId,
      epoch: epoch,
      encryptedProfile: encryptedProfile,
      grants: grants,
      revokedMemberUids: revokedMemberUids,
      signatureBytes: signature,
    );
  }
}

/// Rotates a traveller's profile key and signs the resulting bundle.
///
/// The caller MUST obtain:
/// - the current epoch from independently trusted state;
/// - the active recipient roster from a verified authorisation process;
/// - device trust pins from an authenticated channel.
///
/// Never infer authorisation from Firestore data alone.
class TravellerProfileKeyRotation {
  final TripTravellerE2eeBridge _bridge = TripTravellerE2eeBridge();
  final AuthenticatedProfileKeyExchange _exchange =
      AuthenticatedProfileKeyExchange();
  final Ed25519 _signatures = Ed25519();

  Future<SignedProfileKeyRotation> rotate({
    required TripTravellerProfileData profile,
    required String tripId,
    required String profileUid,
    required String senderDeviceId,
    required int previousEpoch,
    required Set<String> revokedMemberUids,
    required List<ProfileRotationRecipient> activeRecipients,
    required SimpleKeyPair senderX25519KeyPair,
    required SimpleKeyPair senderEd25519KeyPair,
  }) async {
    if (tripId.trim().isEmpty ||
        profileUid.trim().isEmpty ||
        senderDeviceId.trim().isEmpty ||
        previousEpoch < 1 ||
        previousEpoch >= 2147483647 ||
        activeRecipients.isEmpty) {
      throw StateError('Invalid profile rotation request.');
    }

    final revoked = revokedMemberUids.toList()..sort();

    if (revoked.any((uid) => uid.trim().isEmpty)) {
      throw StateError('Invalid revoked member identity.');
    }

    final recipients = [...activeRecipients]
      ..sort((a, b) {
        final byUid = a.uid.compareTo(b.uid);
        return byUid != 0 ? byUid : a.deviceId.compareTo(b.deviceId);
      });

    final recipientIds = <String>{};

    for (final recipient in recipients) {
      final identity = jsonEncode([recipient.uid, recipient.deviceId]);

      if (recipient.uid.trim().isEmpty ||
          recipient.deviceId.trim().isEmpty ||
          revokedMemberUids.contains(recipient.uid) ||
          !recipientIds.add(identity)) {
        throw StateError('Invalid or revoked rotation recipient.');
      }
    }

    // A copy must remain available to the profile owner's current device.
    if (!recipients.any(
      (recipient) =>
          recipient.uid == profileUid && recipient.deviceId == senderDeviceId,
    )) {
      throw StateError('The profile owner must retain an authorised key.');
    }

    final nextEpoch = previousEpoch + 1;
    final nextKey = await AesGcm.with256bits().newSecretKey();

    // Re-encryption takes place on the client's device.
    final encrypted = await _bridge.sealEditedProfile(
      profile: profile,
      profileKey: nextKey,
      tripId: tripId,
      memberUid: profileUid,
    );

    final grants = <SignedTravellerProfileKeyGrant>[];

    for (final recipient in recipients) {
      grants.add(
        await _exchange.issue(
          tripId: tripId,
          profileUid: profileUid,
          senderUid: profileUid,
          recipientUid: recipient.uid,
          senderDeviceId: senderDeviceId,
          recipientDeviceId: recipient.deviceId,
          keyEpoch: nextEpoch,
          profileKey: nextKey,
          senderX25519KeyPair: senderX25519KeyPair,
          senderEd25519KeyPair: senderEd25519KeyPair,
          recipientX25519PublicKey: recipient.x25519PublicKey,
          trustedRecipient: recipient.trustedPublicKey,
        ),
      );
    }

    final unsigned = SignedProfileKeyRotation(
      tripId: tripId,
      profileUid: profileUid,
      senderDeviceId: senderDeviceId,
      epoch: nextEpoch,
      encryptedProfile: encrypted,
      grants: grants,
      revokedMemberUids: revoked,
      signatureBytes: const [],
    );

    final signature = await _signatures.sign(
      unsigned.signingBytes,
      keyPair: senderEd25519KeyPair,
    );

    return unsigned.withSignature(signature.bytes);
  }

  Future<TripTravellerProfileData> openForRecipient({
    required SignedProfileKeyRotation rotation,
    required String expectedTripId,
    required String expectedProfileUid,
    required String expectedSenderDeviceId,
    required String recipientUid,
    required String recipientDeviceId,
    required int minimumTrustedEpoch,
    required TrustedDevicePublicKey trustedSenderX25519,
    required SimplePublicKey pinnedSenderEd25519,
    required SimpleKeyPair recipientX25519KeyPair,
  }) async {
    if (rotation.tripId != expectedTripId ||
        rotation.profileUid != expectedProfileUid ||
        rotation.senderDeviceId != expectedSenderDeviceId ||
        rotation.epoch < minimumTrustedEpoch ||
        rotation.epoch <= 1 ||
        rotation.signatureBytes.length != 64 ||
        rotation.revokedMemberUids.contains(recipientUid)) {
      throw StateError('Invalid or outdated profile rotation.');
    }

    if (pinnedSenderEd25519.type != KeyPairType.ed25519) {
      throw StateError('Unexpected signing key type.');
    }

    final revoked = rotation.revokedMemberUids.toList()..sort();

    if (revoked.toSet().length != revoked.length ||
        !const ListEqualityStrings().equals(
          revoked,
          rotation.revokedMemberUids,
        )) {
      throw StateError('Invalid rotation revocation list.');
    }

    final identities = <String>{};

    for (final grant in rotation.grants) {
      final identity = jsonEncode([
        grant.recipientUid,
        grant.recipientDeviceId,
      ]);

      if (grant.tripId != rotation.tripId ||
          grant.profileUid != rotation.profileUid ||
          grant.senderUid != rotation.profileUid ||
          grant.senderDeviceId != rotation.senderDeviceId ||
          grant.keyEpoch != rotation.epoch ||
          rotation.revokedMemberUids.contains(grant.recipientUid) ||
          !identities.add(identity)) {
        throw StateError('Inconsistent rotation key grants.');
      }
    }

    // Verify the whole encrypted payload, epoch and grant list together.
    final valid = await _signatures.verify(
      rotation.signingBytes,
      signature: Signature(
        rotation.signatureBytes,
        publicKey: pinnedSenderEd25519,
      ),
    );

    if (!valid) {
      throw StateError('Invalid profile rotation signature.');
    }

    final matches = rotation.grants
        .where(
          (grant) =>
              grant.recipientUid == recipientUid &&
              grant.recipientDeviceId == recipientDeviceId,
        )
        .toList();

    if (matches.length != 1) {
      throw StateError('No authorised key grant for this device.');
    }

    final profileKey = await _exchange.receive(
      grant: matches.single,
      expectedTripId: rotation.tripId,
      expectedProfileUid: rotation.profileUid,
      expectedSenderUid: rotation.profileUid,
      expectedRecipientUid: recipientUid,
      expectedSenderDeviceId: rotation.senderDeviceId,
      expectedRecipientDeviceId: recipientDeviceId,
      expectedKeyEpoch: rotation.epoch,
      trustedSenderX25519: trustedSenderX25519,
      pinnedSenderEd25519: pinnedSenderEd25519,
      recipientX25519KeyPair: recipientX25519KeyPair,
    );

    return _bridge.openMember(
      transport: rotation.encryptedProfile,
      profileKey: profileKey,
      tripId: rotation.tripId,
      memberUid: rotation.profileUid,
    );
  }
}

/// Small dependency-free comparison for canonical list order.
class ListEqualityStrings {
  const ListEqualityStrings();

  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
