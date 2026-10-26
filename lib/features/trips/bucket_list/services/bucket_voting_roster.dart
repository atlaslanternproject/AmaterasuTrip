import '../models/bucket_priority.dart';
import '../models/bucket_vote_summary.dart';
import 'bucket_itinerary_eligibility.dart';
import 'bucket_priority_calculator.dart';

/// Snapshot of users entitled to vote in a specific trip.
///
/// The owner is included even if absent from memberUids.
/// Empty IDs and duplicates are discarded.
class BucketVotingRoster {
  BucketVotingRoster({
    required String ownerUid,
    required Iterable<String> memberUids,
  }) : participantUids = Set<String>.unmodifiable({
         if (ownerUid.trim().isNotEmpty) ownerUid.trim(),
         ...memberUids.map((uid) => uid.trim()).where((uid) => uid.isNotEmpty),
       });

  final Set<String> participantUids;

  int get participantCount => participantUids.length;

  bool contains(String uid) => participantUids.contains(uid);

  BucketVoteSummary summarize(Map<String, BucketPriority> votesByUid) {
    return BucketPriorityCalculator.calculate(
      participantUids: participantUids,
      votesByUid: votesByUid,
    );
  }

  bool everyoneHasVoted(Map<String, BucketPriority> votesByUid) {
    return BucketItineraryEligibility.everyoneHasVoted(
      participantUids: participantUids,
      votesByUid: votesByUid,
    );
  }

  bool canAddToItinerary(Map<String, BucketPriority> votesByUid) {
    return BucketItineraryEligibility.canAddToItinerary(
      participantUids: participantUids,
      votesByUid: votesByUid,
    );
  }
}
