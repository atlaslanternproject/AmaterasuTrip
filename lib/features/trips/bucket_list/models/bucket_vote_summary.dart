import 'bucket_priority.dart';

class BucketVoteSummary {
  const BucketVoteSummary({
    required this.totalPoints,
    required this.average,
    required this.respondedCount,
    required this.participantCount,
    required this.groupPriority,
  });

  final int totalPoints;
  final double? average;
  final int respondedCount;
  final int participantCount;
  final BucketPriority? groupPriority;

  int get pendingCount => participantCount - respondedCount;

  bool get allVoted =>
      participantCount > 0 && respondedCount == participantCount;

  bool get readyForItinerary => allVoted;
}
