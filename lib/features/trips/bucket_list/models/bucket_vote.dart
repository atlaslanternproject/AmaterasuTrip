import 'bucket_priority.dart';

class BucketVote {
  const BucketVote({required this.userUid, required this.priority});

  final String userUid;
  final BucketPriority priority;

  int get points => priority.points;
}
