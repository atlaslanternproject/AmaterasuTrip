import 'package:cryptography/cryptography.dart';
import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';
import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

/// Experimental E2EE bridge. Not connected to production repositories.
/// Requires an independently authorised key. Never falls back to plaintext.
class TripTravellerE2eeBridge {
  TripTravellerE2eeBridge({TravellerHealthTransportCodec? codec})
    : _codec = codec ?? TravellerHealthTransportCodec();

  final TravellerHealthTransportCodec _codec;

  Future<Map<String, dynamic>> sealInvitation({
    required TripTravellerProfile profile,
    required SecretKey profileKey,
    required String tripId,
    required String memberUid,
  }) => _codec.seal(
    profile: profile.toMap(),
    profileKey: profileKey,
    tripId: tripId,
    memberUid: memberUid,
  );

  Future<Map<String, dynamic>> sealEditedProfile({
    required TripTravellerProfileData profile,
    required SecretKey profileKey,
    required String tripId,
    required String memberUid,
  }) => _codec.seal(
    profile: profile.toMap(),
    profileKey: profileKey,
    tripId: tripId,
    memberUid: memberUid,
  );

  /// Decrypt and validate before constructing the member model.
  /// Do not use the legacy fromMap() on encrypted network payloads.
  Future<TripTravellerProfileData> openMember({
    required Map<String, dynamic> transport,
    required SecretKey profileKey,
    required String tripId,
    required String memberUid,
  }) async {
    final profile = await _codec.open(
      transport: transport,
      profileKey: profileKey,
      tripId: tripId,
      memberUid: memberUid,
    );

    return TripTravellerProfileData(
      hasEsimOrInternet: profile['hasEsimOrInternet'] as bool?,
      hasCheckedBaggage: profile['hasCheckedBaggage'] as bool?,
      hasCabinBaggage10Kg: profile['hasCabinBaggage10Kg'] as bool?,
      hasAllergies: profile['hasAllergies'] as bool?,
      hasIntolerances: profile['hasIntolerances'] as bool?,
      hasMedicalAccessibilityInfo:
          profile['hasMedicalAccessibilityInfo'] as bool?,
      allergies: profile['allergies'] as String,
      intolerances: profile['intolerances'] as String,
      medicalAccessibilityInfo: profile['medicalAccessibilityInfo'] as String,
      emergencyContactName: profile['emergencyContactName'] as String,
      emergencyContactPhone: profile['emergencyContactPhone'] as String,
    );
  }
}
