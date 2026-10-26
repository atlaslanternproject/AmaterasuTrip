import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';

import '../services/bucket_voting_roster.dart';

/// Reads the current trip membership without duplicating its data.
///
/// Loading and error states are preserved. The UI must not treat
/// a missing snapshot as a completed vote.
final bucketVotingRosterProvider =
    Provider.family<AsyncValue<BucketVotingRoster?>, String>((ref, tripId) {
      final tripState = ref.watch(tripProvider(tripId));

      return tripState.whenData((trip) {
        if (trip == null) return null;

        return BucketVotingRoster(
          ownerUid: trip.ownerUid,
          memberUids: trip.memberUids,
        );
      });
    });
