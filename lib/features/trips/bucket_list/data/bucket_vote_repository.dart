import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bucket_priority.dart';
import 'bucket_firestore_access.dart';
import 'bucket_firestore_paths.dart';

/// One vote document per Firebase UID.
/// There is no API for modifying another person's vote.
class BucketVoteRepository {
  BucketVoteRepository(FirebaseFirestore firestore, FirebaseAuth auth)
    : _firestore = firestore,
      _access = BucketFirestoreAccess(firestore, auth);

  final FirebaseFirestore _firestore;
  final BucketFirestoreAccess _access;

  Future<Map<String, BucketPriority>> fetchVotes({
    required String tripId,
    required String activityId,
  }) async {
    _access.currentUid;

    final snapshot = await _firestore
        .collection(BucketFirestorePaths.votes(tripId, activityId))
        .get();

    final result = <String, BucketPriority>{};

    for (final doc in snapshot.docs) {
      final code = doc.data()['priority'];
      if (code is! String) {
        throw FormatException('Invalid priority for ${doc.id}');
      }
      result[doc.id] = BucketPriority.fromCode(code);
    }

    return result;
  }

  Future<void> saveMyVote({
    required String tripId,
    required String activityId,
    required BucketPriority priority,
  }) async {
    await _access.requireMember(tripId);
    final uid = _access.currentUid;

    // Rules must enforce that document ID == request.auth.uid.
    await _firestore
        .doc(BucketFirestorePaths.vote(tripId, activityId, uid))
        .set({
          'priority': priority.name.toUpperCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
