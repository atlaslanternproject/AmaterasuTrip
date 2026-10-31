// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodPriority on _TripBucketListPageState {
  String _priorityFor(BucketListItem item) {
    final votes = _itemVotes[item.id] ?? const <String, BucketPriority>{};
    var points = 0;
    var count = 0;
    for (final uid in _members) {
      final p = votes[uid];
      if (p != null) {
        points += p.points;
        count++;
      }
    }
    if (count == 0) {
      return '-';
    }
    final avg = points / count;
    return avg >= 8.5
        ? 'SS'
        : avg >= 6
        ? 'S'
        : avg >= 3
        ? 'A'
        : 'B';
  }
}
