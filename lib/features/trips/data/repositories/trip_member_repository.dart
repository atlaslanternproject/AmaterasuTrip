import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amaterasutrip/features/trips/models/trip_member.dart';
import 'package:amaterasutrip/features/trips/models/trip_organizational_profile.dart';

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

    // The server has already verified active trip membership.
    // Read only roster metadata and non-medical organizational answers.
    // Legacy encrypted questionnaires are deliberately not opened.
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

      // Never pass old encrypted or legacy medical answers to the UI.
      // The new organizationalProfile is a separate, validated field.

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

  /// Saves only the three non-medical organizational answers.
  /// This does not read or overwrite the old encrypted questionnaire.
  Future<void> saveMyOrganizationalProfile({
    required String tripId,
    required TripOrganizationalProfile profile,
  }) async {
    if (!profile.isComplete) {
      throw StateError('Complete all organizational questions.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign-in required.');
    }

    final result = await _functions
        .httpsCallable('saveMyTripOrganizationalProfile')
        .call<Map<String, dynamic>>({
          'tripId': tripId,
          'organizationalProfile': profile.toMap(),
        });

    if (result.data['updated'] != true ||
        result.data['tripId'] != tripId ||
        result.data['uid'] != uid) {
      throw StateError('Organizational profile was not confirmed.');
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

    return TripMemberRemovalResult(
      removed: true,
      leftTrip: data['leftTrip'] == true,
    );
  }
}
