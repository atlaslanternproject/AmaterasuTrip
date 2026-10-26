import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bucket_list_item.dart';
import '../models/bucket_list_item_codec.dart';
import 'bucket_firestore_access.dart';
import 'bucket_firestore_paths.dart';

/// Small, page-based reads. No permanent listener on the full collection.
class BucketActivityRepository {
  BucketActivityRepository(FirebaseFirestore firestore, FirebaseAuth auth)
    : _firestore = firestore,
      _access = BucketFirestoreAccess(firestore, auth);

  final FirebaseFirestore _firestore;
  final BucketFirestoreAccess _access;

  CollectionReference<Map<String, dynamic>> _collection(String tripId) =>
      _firestore.collection(BucketFirestorePaths.activities(tripId));

  Future<BucketActivityPage> fetchPage({
    required String tripId,
    int pageSize = 20,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }

    _access.currentUid;

    Query<Map<String, dynamic>> query = _collection(
      tripId,
    ).orderBy('createdAt').limit(pageSize);

    if (after != null) {
      query = query.startAfterDocument(after);
    }

    final snapshot = await query.get();

    return BucketActivityPage(
      items: snapshot.docs
          .map(
            (doc) => BucketListItemCodec.fromMap(id: doc.id, data: doc.data()),
          )
          .toList(growable: false),
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  Future<BucketListItem?> getActivity({
    required String tripId,
    required String activityId,
  }) async {
    _access.currentUid;

    final doc = await _collection(tripId).doc(activityId).get();
    final data = doc.data();

    if (data == null) return null;

    return BucketListItemCodec.fromMap(id: doc.id, data: data);
  }

  /// The UI will generate a new ID through newActivityId().
  String newActivityId(String tripId) => _collection(tripId).doc().id;

  Future<void> create(BucketListItem item) async {
    item.validate();
    await _access.requireMember(item.tripId);

    if (item.createdByUid != _access.currentUid) {
      throw StateError('Creator must be current user');
    }

    final ref = _collection(item.tripId).doc(item.id);
    final data = BucketListItemCodec.toMap(item);

    await _firestore.runTransaction((transaction) async {
      final previous = await transaction.get(ref);

      if (previous.exists) {
        throw StateError('Activity ID already exists');
      }

      transaction.set(ref, data);
    });
  }

  /// Only shared fields may change; identity fields stay immutable.
  Future<void> update(BucketListItem item) async {
    item.validate();
    await _access.requireMember(item.tripId);

    final ref = _collection(item.tripId).doc(item.id);
    final desired = BucketListItemCodec.toMap(item);

    await _firestore.runTransaction((transaction) async {
      final previous = await transaction.get(ref);
      final existing = previous.data();

      if (existing == null) {
        throw StateError('Activity not found');
      }

      for (final key in ['tripId', 'createdByUid', 'createdAt']) {
        if (existing[key] != desired[key]) {
          throw StateError('Immutable activity field changed: $key');
        }
      }

      if (item.updatedAt.isBefore(
        DateTime.parse(existing['updatedAt'] as String),
      )) {
        throw StateError('Outdated activity update');
      }

      transaction.update(ref, {
        'name': desired['name'],
        'city': desired['city'],
        'country': desired['country'],
        'type': desired['type'],
        'durationMinutes': desired['durationMinutes'],
        'notes': desired['notes'],
        'usefulLinks': desired['usefulLinks'],
        'googlePlaceId': desired['googlePlaceId'],
        'address': desired['address'],
        'latitude': desired['latitude'],
        'longitude': desired['longitude'],
        'updatedAt': desired['updatedAt'],
      });
    });
  }
}

class BucketActivityPage {
  const BucketActivityPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<BucketListItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}
