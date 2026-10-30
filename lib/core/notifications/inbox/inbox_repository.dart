import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'inbox_notification.dart';

class InboxRepository {
  InboxRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Authentication required');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore
        .collection('viaggiatori')
        .doc(_uid)
        .collection('notifications');
  }

  Stream<List<InboxNotification>> watchActive({int limit = 50}) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(InboxNotification.fromFirestore)
              .where(
                (notification) =>
                    !notification.isArchived && !notification.isDeleted,
              )
              .toList(growable: false);
        });
  }

  Stream<List<InboxNotification>> watchArchived({int limit = 50}) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(InboxNotification.fromFirestore)
              .where(
                (notification) =>
                    notification.isArchived && !notification.isDeleted,
              )
              .toList(growable: false);
        });
  }

  Future<void> markRead(String notificationId) async {
    await _collection.doc(notificationId).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archive(String notificationId) async {
    await _collection.doc(notificationId).update({
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restore(String notificationId) async {
    await _collection.doc(notificationId).update({'archivedAt': null});
  }

  Future<void> delete(String notificationId) async {
    await _collection.doc(notificationId).update({
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}
