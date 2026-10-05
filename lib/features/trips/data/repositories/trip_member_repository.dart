import 'package:cloud_functions/cloud_functions.dart';

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

    final members = rawMembers
        .whereType<Map>()
        .map((raw) => TripMember.fromMap(Map<String, dynamic>.from(raw)))
        .where((member) => member.uid.isNotEmpty)
        .toList();

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

  Future<void> updateMyTravellerProfile({
    required String tripId,
    required TripTravellerProfileData profile,
  }) async {
    final callable = _functions.httpsCallable('updateMyTripTravellerProfile');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'travellerProfile': profile.toMap(),
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

    return TripMemberRemovalResult(
      removed: true,
      leftTrip: data['leftTrip'] == true,
    );
  }
}
