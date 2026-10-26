import '../models/bucket_priority.dart';
import 'bucket_priority_calculator.dart';

abstract final class BucketItineraryEligibility {
  static bool everyoneHasVoted({
    required Iterable<String> participantUids,
    required Map<String, BucketPriority> votesByUid,
  }) {
    return BucketPriorityCalculator.calculate(
      participantUids: participantUids,
      votesByUid: votesByUid,
    ).allVoted;
  }

  // The itinerary module is not available yet.
  // This flag must remain false until that module is implemented.
  static const bool itineraryFeatureEnabled = false;

  static bool canAddToItinerary({
    required Iterable<String> participantUids,
    required Map<String, BucketPriority> votesByUid,
  }) {
    return itineraryFeatureEnabled &&
        everyoneHasVoted(
          participantUids: participantUids,
          votesByUid: votesByUid,
        );
  }
}
