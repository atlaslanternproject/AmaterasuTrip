import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bucket_deletion_request.dart';
import '../services/bucket_deletion_policy.dart';
import 'bucket_deletion_paths.dart';
import 'bucket_firestore_access.dart';
import 'bucket_firestore_paths.dart';

/// Client operations only; Firestore Rules remain authoritative.
///
/// Approval records a decision but does not delete the activity.
class BucketDeletionRepository {
  BucketDeletionRepository(FirebaseFirestore firestore, FirebaseAuth auth)
    : _firestore = firestore,
      _access = BucketFirestoreAccess(firestore, auth);

  final FirebaseFirestore _firestore;
  final BucketFirestoreAccess _access;

  CollectionReference<Map<String, dynamic>> _requests(
    String tripId,
    String activityId,
  ) {
    return _firestore.collection(
      BucketDeletionPaths.requests(tripId, activityId),
    );
  }

  Future<String> requestDeletion({
    required String tripId,
    required String activityId,
    String reason = '',
  }) async {
    final uid = _access.currentUid;

    if (reason.trim().length > 500) {
      throw ArgumentError.value(reason, 'reason');
    }

    await _access.requireMember(tripId);

    final tripSnapshot = await _firestore.collection('trips').doc(tripId).get();

    final trip = tripSnapshot.data();
    if (trip == null) {
      throw StateError('Trip not found');
    }

    final ownerUid = trip['ownerUid'];
    final members = trip['memberUids'];

    if (ownerUid is! String || members is! List) {
      throw StateError('Invalid trip membership');
    }

    if (!BucketDeletionPolicy.canRequest(
      actorUid: uid,
      ownerUid: ownerUid,
      memberUids: members.whereType<String>(),
    )) {
      throw StateError('Not allowed to request deletion');
    }

    final activity = await _firestore
        .doc(BucketFirestorePaths.activity(tripId, activityId))
        .get();

    if (!activity.exists) {
      throw StateError('Activity not found');
    }

    // One request per user/activity. Repeated requests do not
    // create unlimited documents or extra notification events.
    final ref = _requests(tripId, activityId).doc(uid);

    await _firestore.runTransaction((transaction) async {
      final previous = await transaction.get(ref);

      if (previous.exists) {
        throw StateError('A deletion request already exists');
      }

      transaction.set(ref, {
        'activityId': activityId,
        'requestedByUid': uid,
        'reason': reason.trim(),
        'status': BucketDeletionStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return ref.id;
  }

  Future<List<BucketDeletionRequest>> getRequests({
    required String tripId,
    required String activityId,
    int limit = 50,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit');
    }

    await _access.requireMember(tripId);

    final snapshot = await _requests(tripId, activityId).limit(limit).get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final statusName = data['status'];

          if (statusName is! String) {
            throw const FormatException('Invalid deletion status');
          }

          final status = BucketDeletionStatus.values.firstWhere(
            (value) => value.name == statusName,
            orElse: () =>
                throw const FormatException('Unknown deletion status'),
          );

          final created = data['createdAt'];
          final reviewed = data['reviewedAt'];

          if (created is! Timestamp) {
            throw const FormatException('Missing creation timestamp');
          }

          final request = BucketDeletionRequest(
            id: doc.id,
            activityId: data['activityId'] as String? ?? '',
            requestedByUid: data['requestedByUid'] as String? ?? '',
            reason: data['reason'] as String? ?? '',
            status: status,
            createdAt: created.toDate(),
            reviewedByUid: data['reviewedByUid'] as String?,
            reviewedAt: reviewed is Timestamp ? reviewed.toDate() : null,
          );

          request.validate();
          return request;
        })
        .toList(growable: false);
  }

  Future<void> reviewRequest({
    required String tripId,
    required String activityId,
    required String requestId,
    required bool approve,
  }) async {
    final uid = _access.currentUid;
    await _access.requireMember(tripId);

    final trip = await _firestore.collection('trips').doc(tripId).get();

    if (trip.data()?['ownerUid'] != uid) {
      throw StateError('Only the trip owner can review requests');
    }

    final ref = _firestore.doc(
      BucketDeletionPaths.request(tripId, activityId, requestId),
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();

      if (data == null) {
        throw StateError('Deletion request not found');
      }

      if (!BucketDeletionPolicy.canReview(
        actorUid: uid,
        ownerUid: uid,
        status: _parseStatus(data['status']),
      )) {
        throw StateError('Request cannot be reviewed');
      }

      transaction.update(ref, {
        'status': approve
            ? BucketDeletionStatus.approved.name
            : BucketDeletionStatus.rejected.name,
        'reviewedByUid': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static BucketDeletionStatus _parseStatus(Object? raw) {
    if (raw is! String) {
      throw const FormatException('Invalid deletion status');
    }

    return BucketDeletionStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw const FormatException('Unknown deletion status'),
    );
  }
}
