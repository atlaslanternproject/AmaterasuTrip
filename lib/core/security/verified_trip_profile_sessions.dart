import 'package:cryptography/cryptography.dart';

import 'authenticated_profile_key_exchange.dart';
import 'signed_trip_device_roster.dart';
import 'traveller_profile_key_rotation.dart';
import 'trusted_device_public_key.dart';
import 'verified_trip_rotation_reader.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';

/// A short-lived, device-bound key lease. This class cannot be instantiated
/// outside this library and cannot be created from arbitrary Firebase data.
/// It is NOT a substitute for checking fresh server membership or revocation.
final class VerifiedTripProfileKeyLease {
  VerifiedTripProfileKeyLease._(
    this._profileKey,
    this._epochStore, {
    required this.tripId,
    required this.profileUid,
    required this.recipientUid,
    required this.recipientDeviceId,
    required this.keyEpoch,
  }) : _expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 2));

  final String tripId;
  final String profileUid;
  final String recipientUid;
  final String recipientDeviceId;
  final int keyEpoch;
  final SecretKey _profileKey;
  final TrustedTripEpochStore _epochStore;
  final DateTime _expiresAt;

  Future<SecretKey> requireKey({
    required String tripId,
    required String profileUid,
    required String currentUserUid,
  }) async {
    if (this.tripId != tripId ||
        this.profileUid != profileUid ||
        recipientUid != currentUserUid ||
        !DateTime.now().toUtc().isBefore(_expiresAt)) {
      throw StateError('E2EE profile session is not authorised.');
    }

    // A missing or regressed epoch, a newer rotation, or storage failure
    // stops the operation. Do not fetch the floor from Firestore.
    final floor = await _epochStore.readTrustedFloor(tripId);
    if (floor != keyEpoch) {
      throw StateError('E2EE profile key is stale or untrusted.');
    }
    return _profileKey;
  }
}

/// The only entry to an authenticated in-memory profile-key session.
/// Requires a separately pinned trip authority and profile signer,
/// recipient private device key, and monotonic trusted epoch storage.
///
/// The host app still needs to supply verified onboarding, real membership
/// checks, remote grant transport, recovery and revocation synchronisation.
/// There is deliberately NO automatic first-device bootstrap or key fallback.
final class VerifiedTripProfileSessions {
  VerifiedTripProfileSessions();

  static final VerifiedTripProfileSessions instance =
      VerifiedTripProfileSessions();

  final Map<String, VerifiedTripProfileKeyLease> _leases = {};

  String _id(String tripId, String profileUid, String recipientUid) =>
      '$tripId\u0000$profileUid\u0000$recipientUid';

  Future<void> unlockFromVerifiedRotation({
    required SignedTripDeviceRoster roster,
    required SignedProfileKeyRotation rotation,
    required String tripId,
    required String authorityUid,
    required String authorityDeviceId,
    required SimplePublicKey pinnedAuthorityEd25519,
    required TrustedDevicePublicKey trustedSenderX25519,
    required SimplePublicKey pinnedSenderEd25519,
    required String recipientUid,
    required String recipientDeviceId,
    required SimpleKeyPair recipientX25519KeyPair,
    required TrustedTripEpochStore trustedEpochStore,
  }) async {
    final identity = _id(tripId, rotation.profileUid, recipientUid);
    _leases.remove(identity);

    if (rotation.tripId != tripId ||
        rotation.profileUid.trim().isEmpty ||
        recipientUid.trim().isEmpty ||
        recipientDeviceId.trim().isEmpty) {
      throw StateError('Invalid E2EE unlock identity.');
    }

    // Validates both signatures, complete recipient roster, epoch floor,
    // encryption and the recipient device. Advances trusted state first.
    await VerifiedTripRotationReader(trustedEpochStore).open(
      roster: roster,
      rotation: rotation,
      tripId: tripId,
      authorityUid: authorityUid,
      authorityDeviceId: authorityDeviceId,
      pinnedAuthorityEd25519: pinnedAuthorityEd25519,
      trustedSenderX25519: trustedSenderX25519,
      pinnedSenderEd25519: pinnedSenderEd25519,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      recipientX25519KeyPair: recipientX25519KeyPair,
    );

    final matches = rotation.grants
        .where(
          (grant) =>
              grant.recipientUid == recipientUid &&
              grant.recipientDeviceId == recipientDeviceId,
        )
        .toList();
    if (matches.length != 1) {
      throw StateError('Missing verified E2EE grant.');
    }

    final key = await AuthenticatedProfileKeyExchange().receive(
      grant: matches.single,
      expectedTripId: tripId,
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

    // Confirm the recovered key actually opens the signed profile payload.
    await TripTravellerE2eeBridge().openMember(
      transport: rotation.encryptedProfile,
      profileKey: key,
      tripId: tripId,
      memberUid: rotation.profileUid,
    );

    if (await trustedEpochStore.readTrustedFloor(tripId) != rotation.epoch) {
      throw StateError('E2EE epoch changed while unlocking.');
    }

    _leases[identity] = VerifiedTripProfileKeyLease._(
      key,
      trustedEpochStore,
      tripId: tripId,
      profileUid: rotation.profileUid,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      keyEpoch: rotation.epoch,
    );
  }

  Future<VerifiedTripProfileKeyLease> requireLease({
    required String tripId,
    required String profileUid,
    required String currentUserUid,
  }) async {
    final lease = _leases[_id(tripId, profileUid, currentUserUid)];
    if (lease == null) {
      throw StateError('Verify this device and unlock E2EE before continuing.');
    }
    try {
      await lease.requireKey(
        tripId: tripId,
        profileUid: profileUid,
        currentUserUid: currentUserUid,
      );
    } catch (_) {
      _leases.remove(_id(tripId, profileUid, currentUserUid));
      rethrow;
    }
    return lease;
  }

  /// Call on sign-out, account switch, trip exit, or trusted-roster change.
  void clear() => _leases.clear();

  void clearTrip(String tripId) {
    _leases.removeWhere((_, lease) => lease.tripId == tripId);
  }
}
