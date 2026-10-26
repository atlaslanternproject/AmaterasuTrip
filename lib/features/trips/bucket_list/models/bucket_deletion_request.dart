enum BucketDeletionStatus { pending, approved, rejected }

class BucketDeletionRequest {
  const BucketDeletionRequest({
    required this.id,
    required this.activityId,
    required this.requestedByUid,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedByUid,
    this.reviewedAt,
  });

  final String id;
  final String activityId;
  final String requestedByUid;
  final String reason;
  final BucketDeletionStatus status;
  final DateTime createdAt;
  final String? reviewedByUid;
  final DateTime? reviewedAt;

  bool get isPending => status == BucketDeletionStatus.pending;

  void validate() {
    if (id.trim().isEmpty ||
        activityId.trim().isEmpty ||
        requestedByUid.trim().isEmpty) {
      throw ArgumentError('Required deletion request field is empty');
    }

    if (reason.trim().length > 500) {
      throw ArgumentError('Deletion reason exceeds 500 characters');
    }

    if (isPending) {
      if (reviewedByUid != null || reviewedAt != null) {
        throw ArgumentError('Pending request cannot be reviewed');
      }
    } else {
      if (reviewedByUid == null ||
          reviewedByUid!.trim().isEmpty ||
          reviewedAt == null) {
        throw ArgumentError('Decision requires reviewer and date');
      }

      if (reviewedAt!.isBefore(createdAt)) {
        throw ArgumentError('Review date precedes request date');
      }
    }
  }
}
