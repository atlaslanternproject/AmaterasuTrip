// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodLoadCategories on _TripBucketListPageState {
  Future<void> _loadCategories() async {
    try {
      final docs = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('bucketCategories')
          .get();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(
            docs.docs
                .map((d) => d.data()['label'])
                .whereType<String>()
                .toSet()
                .toList()
              ..sort(),
          );
      });
    } catch (_) {
      // Existing activities must remain usable if category suggestions fail.
    }
  }
}
