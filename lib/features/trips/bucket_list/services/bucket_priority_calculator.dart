import '../models/bucket_priority.dart';
import '../models/bucket_vote_summary.dart';

abstract final class BucketPriorityCalculator {
  static BucketVoteSummary calculate({
    required Iterable<String> participantUids,
    required Map<String, BucketPriority> votesByUid,
  }) {
    final participants = participantUids
        .where((uid) => uid.trim().isNotEmpty)
        .toSet();

    final scores = <int>[];

    for (final uid in participants) {
      final priority = votesByUid[uid];

      if (priority != null) {
        scores.add(priority.points);
      }
    }

    final total = scores.fold<int>(0, (sum, score) => sum + score);

    final average = scores.isEmpty ? null : total / scores.length;

    return BucketVoteSummary(
      totalPoints: total,
      average: average,
      respondedCount: scores.length,
      participantCount: participants.length,
      groupPriority: _groupPriority(average),
    );
  }

  static BucketPriority? _groupPriority(double? average) {
    if (average == null) return null;
    if (average >= 8.5) return BucketPriority.ss;
    if (average >= 6) return BucketPriority.s;
    if (average >= 3) return BucketPriority.a;
    return BucketPriority.b;
  }
}
