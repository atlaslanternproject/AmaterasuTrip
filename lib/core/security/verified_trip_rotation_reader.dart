import 'package:cryptography/cryptography.dart';

import 'signed_trip_device_roster.dart';
import 'traveller_profile_key_rotation.dart';
import 'trusted_device_public_key.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

/// Implementations MUST use an independently trusted, persistent,
/// monotonic epoch floor. Firestore alone is not a trusted epoch store.
/// A failed read/write must throw rather than silently reset trust.
abstract interface class TrustedTripEpochStore {
  Future<int?> readTrustedFloor(String tripId);

  Future<void> advanceTrustedFloor(String tripId, int verifiedEpoch);
}

/// Fail-closed E2EE reader.
///
/// No plaintext is returned unless:
/// 1. an independently established epoch floor exists;
/// 2. the signed roster and rotation have been verified;
/// 3. the recipient decrypts with their own private key;
/// 4. the trusted epoch store accepts the verified epoch.
///
/// This component does not establish first-device trust, validate live
/// Firebase membership, or implement production secure storage.
class VerifiedTripRotationReader {
  VerifiedTripRotationReader(this._store);

  final TrustedTripEpochStore _store;
  final SignedTripDeviceRosterVerifier _verifier =
      SignedTripDeviceRosterVerifier();

  Future<TripTravellerProfileData> open({
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
  }) async {
    if (tripId.trim().isEmpty ||
        authorityUid.trim().isEmpty ||
        authorityDeviceId.trim().isEmpty ||
        recipientUid.trim().isEmpty ||
        recipientDeviceId.trim().isEmpty) {
      throw StateError('Invalid trusted rotation context.');
    }

    // No fallback to an untrusted Firebase field or a default epoch.
    final trustedFloor = await _store.readTrustedFloor(tripId);

    if (trustedFloor == null ||
        trustedFloor < 2 ||
        trustedFloor >= 2147483647) {
      throw StateError('Trusted E2EE epoch bootstrap is required.');
    }

    final profile = await _verifier.openVerifiedRotation(
      roster: roster,
      rotation: rotation,
      expectedTripId: tripId,
      expectedAuthorityUid: authorityUid,
      expectedAuthorityDeviceId: authorityDeviceId,
      minimumTrustedEpoch: trustedFloor,
      pinnedAuthorityEd25519: pinnedAuthorityEd25519,
      trustedSenderX25519: trustedSenderX25519,
      pinnedSenderEd25519: pinnedSenderEd25519,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      recipientX25519KeyPair: recipientX25519KeyPair,
    );

    // The implementation must atomically refuse a regression if another
    // operation has already advanced the trusted floor.
    // If persistence fails, do NOT return the decrypted questionnaire.
    await _store.advanceTrustedFloor(tripId, roster.epoch);

    return profile;
  }
}
