import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Local preflight only. Firestore Security Rules remain authoritative.
class BucketFirestoreAccess {
  const BucketFirestoreAccess(this.firestore, this.auth);

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  String get currentUid {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Authentication required');
    }
    return uid;
  }

  Future<void> requireMember(String tripId) async {
    final uid = currentUid;
    final snapshot = await firestore.collection('trips').doc(tripId).get();
    final data = snapshot.data();

    if (data == null) {
      throw StateError('Trip not found');
    }

    final members = data['memberUids'];
    final isMember =
        data['ownerUid'] == uid || (members is List && members.contains(uid));

    if (!isMember) {
      throw StateError('Trip membership required');
    }
  }
}
