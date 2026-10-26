import '../models/bucket_deletion_request.dart';

abstract final class BucketDeletionPolicy {
  static bool canRequest({
    required String actorUid,
    required String ownerUid,
    required Iterable<String> memberUids,
  }) {
    return actorUid.isNotEmpty &&
        actorUid != ownerUid &&
        memberUids.contains(actorUid);
  }

  static bool canReview({
    required String actorUid,
    required String ownerUid,
    required BucketDeletionStatus status,
  }) {
    return actorUid.isNotEmpty &&
        actorUid == ownerUid &&
        status == BucketDeletionStatus.pending;
  }

  static bool canDeleteDirectly({
    required String actorUid,
    required String ownerUid,
  }) {
    return actorUid.isNotEmpty && actorUid == ownerUid;
  }
}
