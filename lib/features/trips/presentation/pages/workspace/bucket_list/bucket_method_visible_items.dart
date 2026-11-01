// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodVisibleItems on _TripBucketListPageState {
  List<BucketListItem> get _visibleItems {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final list = _items.where((item) {
      final term = _filterSearch.trim().toLowerCase();
      final searchable = [
        item.name,
        item.city,
        item.country,
        item.address ?? '',
        item.customCategory ?? '',
        item.type.name,
      ].join(' ').toLowerCase();
      if (term.isNotEmpty && !searchable.contains(term)) return false;
      final votes = _itemVotes[item.id] ?? const <String, BucketPriority>{};
      final count = _members.where((m) => votes.containsKey(m)).length;
      if (_filterCity.isNotEmpty && item.city != _filterCity) {
        return false;
      }
      final category = item.customCategory?.trim().isNotEmpty == true
          ? item.customCategory!
          : item.type.name;
      if (_filterCategory.isNotEmpty &&
          _categoryKey(category) != _categoryKey(_filterCategory)) {
        return false;
      }
      if (_filterPriority.isNotEmpty && _priorityFor(item) != _filterPriority) {
        return false;
      }
      if (_filterVoting == 'complete' && count != _members.length) {
        return false;
      }
      if (_filterVoting == 'pending' && count == _members.length) {
        return false;
      }
      if (_filterMine == 'voted' && !votes.containsKey(uid)) {
        return false;
      }
      if (_filterMine == 'pending' && votes.containsKey(uid)) {
        return false;
      }
      return true;
    }).toList();
    int rank(String p) => switch (p) {
      'SS' => 4,
      'S' => 3,
      'A' => 2,
      'B' => 1,
      _ => 0,
    };
    list.sort((a, b) {
      int result;
      switch (_sortMode) {
        case 'average':
          result = _averageFor(a).compareTo(_averageFor(b));
        case 'interested':
          result = (_itemVotes[a.id]?.length ?? 0).compareTo(
            _itemVotes[b.id]?.length ?? 0,
          );
        case 'city':
          result = a.city.toLowerCase().compareTo(b.city.toLowerCase());
        case 'name':
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'date':
          result = a.createdAt.compareTo(b.createdAt);
        default:
          result = rank(_priorityFor(a)).compareTo(rank(_priorityFor(b)));
      }
      if (result == 0) result = a.id.compareTo(b.id);
      return _sortAscending ? result : -result;
    });
    return list;
  }
}
