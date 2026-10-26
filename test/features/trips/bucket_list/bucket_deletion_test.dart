import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_deletion_paths.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_deletion_request.dart';
import 'package:amaterasutrip/features/trips/bucket_list/services/bucket_deletion_policy.dart';

void main() {
  test('Request path belongs to the activity and trip', () {
    expect(
      BucketDeletionPaths.request('trip1', 'activity1', 'user1'),
      'trips/trip1/bucketList/activity1/deletionRequests/user1',
    );
  });

  test('Traveler can request deletion', () {
    expect(
      BucketDeletionPolicy.canRequest(
        actorUid: 'traveler',
        ownerUid: 'owner',
        memberUids: ['owner', 'traveler'],
      ),
      isTrue,
    );
  });

  test('Outsider cannot request deletion', () {
    expect(
      BucketDeletionPolicy.canRequest(
        actorUid: 'outsider',
        ownerUid: 'owner',
        memberUids: ['traveler'],
      ),
      isFalse,
    );
  });

  test('Owner uses direct deletion policy, not request flow', () {
    expect(
      BucketDeletionPolicy.canRequest(
        actorUid: 'owner',
        ownerUid: 'owner',
        memberUids: ['owner'],
      ),
      isFalse,
    );

    expect(
      BucketDeletionPolicy.canDeleteDirectly(
        actorUid: 'owner',
        ownerUid: 'owner',
      ),
      isTrue,
    );
  });

  test('Traveler cannot delete directly', () {
    expect(
      BucketDeletionPolicy.canDeleteDirectly(
        actorUid: 'traveler',
        ownerUid: 'owner',
      ),
      isFalse,
    );
  });

  test('Only owner can review pending request', () {
    expect(
      BucketDeletionPolicy.canReview(
        actorUid: 'owner',
        ownerUid: 'owner',
        status: BucketDeletionStatus.pending,
      ),
      isTrue,
    );

    expect(
      BucketDeletionPolicy.canReview(
        actorUid: 'traveler',
        ownerUid: 'owner',
        status: BucketDeletionStatus.pending,
      ),
      isFalse,
    );
  });

  test('Reviewed requests cannot be reviewed again', () {
    expect(
      BucketDeletionPolicy.canReview(
        actorUid: 'owner',
        ownerUid: 'owner',
        status: BucketDeletionStatus.approved,
      ),
      isFalse,
    );

    expect(
      BucketDeletionPolicy.canReview(
        actorUid: 'owner',
        ownerUid: 'owner',
        status: BucketDeletionStatus.rejected,
      ),
      isFalse,
    );
  });

  test('Pending request cannot have reviewer', () {
    final request = BucketDeletionRequest(
      id: 'req',
      activityId: 'activity',
      requestedByUid: 'traveler',
      reason: '',
      status: BucketDeletionStatus.pending,
      createdAt: DateTime.utc(2026, 10, 26),
      reviewedByUid: 'owner',
    );

    expect(() => request.validate(), throwsArgumentError);
  });

  test('Reviewed request must have review metadata', () {
    final request = BucketDeletionRequest(
      id: 'req',
      activityId: 'activity',
      requestedByUid: 'traveler',
      reason: '',
      status: BucketDeletionStatus.approved,
      createdAt: DateTime.utc(2026, 10, 26),
    );

    expect(() => request.validate(), throwsArgumentError);
  });

  test('Valid pending request passes validation', () {
    final request = BucketDeletionRequest(
      id: 'req',
      activityId: 'activity',
      requestedByUid: 'traveler',
      reason: 'Duplicate',
      status: BucketDeletionStatus.pending,
      createdAt: DateTime.utc(2026, 10, 26),
    );

    expect(() => request.validate(), returnsNormally);
  });
}
