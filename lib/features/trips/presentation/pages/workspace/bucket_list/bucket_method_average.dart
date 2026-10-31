// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodAverage on _TripBucketListPageState {
  double _averageFor(BucketListItem item) {
    final votes = _itemVotes[item.id] ?? const <String, BucketPriority>{};
    final values = _members.map((u) => votes[u]).whereType<BucketPriority>();
    return values.isEmpty
        ? 0
        : values.fold<int>(
                0,
                (totalPoints, value) => totalPoints + value.points,
              ) /
              values.length;
  }
}
