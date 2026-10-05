import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/data/repositories/trip_member_repository.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

final tripMemberRepositoryProvider = Provider<TripMemberRepository>((ref) {
  return TripMemberRepository(
    FirebaseFunctions.instanceFor(region: 'europe-west1'),
  );
});

final tripMembersProvider = FutureProvider.autoDispose
    .family<List<TripMember>, String>((ref, tripId) {
      return ref.watch(tripMemberRepositoryProvider).getMembers(tripId);
    });
