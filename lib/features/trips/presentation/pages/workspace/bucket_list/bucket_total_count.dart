part of 'trip_bucket_list_page.dart';

extension _BucketTotalCount on _TripBucketListPageState {
  Future<int> _readBucketTotal() async {
    final result = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('bucketList')
        .count()
        .get();
    return result.count ?? 0;
  }
}
