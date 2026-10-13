import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';
import 'package:amaterasutrip/core/security/verified_trip_profile_sessions.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';

import 'package:amaterasutrip/features/trips/models/trip_member.dart';

class TripMemberRemovalResult {
  const TripMemberRemovalResult({
    required this.removed,
    required this.leftTrip,
  });

  final bool removed;
  final bool leftTrip;
}

class TripMemberRepository {
  TripMemberRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<List<TripMember>> getMembers(String tripId) async {
    final callable = _functions.httpsCallable('listTripMembers');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final rawMembers = result.data['members'];

    if (rawMembers is! List) {
      throw StateError('Invalid listTripMembers response.');
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('Sign-in is required to unlock trip profiles.');
    }

    final members = <TripMember>[];
    for (final raw in rawMembers) {
      if (raw is! Map) {
        throw StateError('Invalid trip member data.');
      }
      final data = Map<String, dynamic>.from(raw);
      final memberUid = data['uid'];
      if (memberUid is! String || memberUid.isEmpty) {
        throw StateError('Invalid trip member identity.');
      }

      final format = data['travellerProfileFormat'];
      final transport = data['travellerProfile'];

      // Never expose an unverified questionnaire.
      // Membership metadata remains separately readable.
      data['travellerProfile'] = null;
      var sensitiveProfileLocked = true;

      if (format == 'encrypted' && transport is Map) {
        try {
          final lease = await VerifiedTripProfileSessions.instance.requireLease(
            tripId: tripId,
            profileUid: memberUid,
            currentUserUid: currentUid,
          );

          final key = await lease.requireKey(
            tripId: tripId,
            profileUid: memberUid,
            currentUserUid: currentUid,
          );

          final profile = await TripTravellerE2eeBridge().openMember(
            transport: Map<String, dynamic>.from(transport),
            profileKey: key,
            tripId: tripId,
            memberUid: memberUid,
          );

          data['travellerProfile'] = profile.toMap();
          sensitiveProfileLocked = false;
        } catch (_) {
          // Fail closed for protected answers.
          // Do not fail the public membership roster.
        }
      } else if (format == 'missing' &&
          transport == null &&
          data['travellerProfileCompleted'] != true) {
        sensitiveProfileLocked = false;
      } else if (format == 'legacy-redacted') {
        // Legacy questionnaire remains inaccessible.
      }

      // Unknown formats and old plaintext responses remain locked.
      data['sensitiveProfileLocked'] = sensitiveProfileLocked;
      members.add(TripMember.fromMap(data));
    }

    members.sort((a, b) {
      if (a.isAdmin != b.isAdmin) {
        return a.isAdmin ? -1 : 1;
      }

      final aJoined = a.joinedAt;
      final bJoined = b.joinedAt;

      if (aJoined == null && bJoined == null) {
        return a.uid.compareTo(b.uid);
      }

      if (aJoined == null) {
        return 1;
      }

      if (bJoined == null) {
        return -1;
      }

      return aJoined.compareTo(bJoined);
    });

    return members;
  }

  /// Blocks legacy plaintext updates before any Cloud Function call.
  Future<void> updateMyTravellerProfile({
    required String tripId,
    required TripTravellerProfileData profile,
  }) async {
    throw StateError(
      'E2EE device setup is required before saving a questionnaire.',
    );
  }

  /// Requires a key already trusted and available on the local device.
  /// The UI must not call this before device/key enrolment is completed.
  Future<void> updateMyTravellerProfileEncrypted({
    required String tripId,
    required TripTravellerProfileData profile,
    required VerifiedTripProfileKeyLease verifiedSession,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign-in is required to encrypt a questionnaire.');
    }

    final profileKey = await verifiedSession.requireKey(
      tripId: tripId,
      profileUid: uid,
      currentUserUid: uid,
    );

    final envelope = await TravellerHealthTransportCodec().seal(
      profile: profile.toMap(),
      profileKey: profileKey,
      tripId: tripId,
      memberUid: uid,
    );

    final callable = _functions.httpsCallable('updateMyTripTravellerProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'travellerProfile': envelope,
    });

    if (result.data['updated'] != true) {
      throw StateError('Invalid updateMyTripTravellerProfile response.');
    }
  }

  Future<TripMemberRemovalResult> removeMember({
    required String tripId,
    required String targetUid,
  }) async {
    final callable = _functions.httpsCallable('removeTripMember');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'targetUid': targetUid,
    });

    final data = result.data;

    if (data['removed'] != true) {
      throw StateError('Invalid removeTripMember response.');
    }

    // Any membership change invalidates the local roster/key leases.
    // This is not a substitute for server-side signed key rotation.
    VerifiedTripProfileSessions.instance.clearTrip(tripId);

    return TripMemberRemovalResult(
      removed: true,
      leftTrip: data['leftTrip'] == true,
    );
  }
}
