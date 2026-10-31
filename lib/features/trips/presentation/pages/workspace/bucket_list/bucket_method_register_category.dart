// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodRegisterCategory on _TripBucketListPageState {
  Future<void> _registerCategory(String raw) async {
    final label = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (label.isEmpty) {
      return;
    }
    final key = _categoryKey(label);
    if (key.isEmpty) {
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('bucketCategories')
        .doc(key);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required');
    }
    try {
      await ref.set({
        'label': label,
        'createdByUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Two travelers may create the same normalized category together.
      if (!(await ref.get()).exists) {
        rethrow;
      }
    }
  }
}
