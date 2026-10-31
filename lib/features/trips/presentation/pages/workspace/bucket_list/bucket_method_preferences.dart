// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodPreferences on _TripBucketListPageState {
  String? get _bucketPreferenceKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return 'amaterasu.bucket.v1.$uid.${widget.tripId}';
  }

  Future<void> _loadBucketPreferences() async {
    final key = _bucketPreferenceKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || key != _bucketPreferenceKey) return;
    setState(() {
      final mode = prefs.getString('$key.view');
      if (mode == 'cards' || mode == 'list' || mode == 'details') {
        _viewMode = mode!;
      }
      final sort = prefs.getString('$key.sort');
      if (const [
        'priority',
        'average',
        'interested',
        'city',
        'name',
        'date',
      ].contains(sort)) {
        _sortMode = sort!;
      }
      _sortAscending = prefs.getBool('$key.asc') ?? false;
      _filterCity = prefs.getString('$key.city') ?? '';
      _filterCategory = prefs.getString('$key.category') ?? '';
      _filterPriority = prefs.getString('$key.priority') ?? '';
      _filterVoting = prefs.getString('$key.voting') ?? '';
      _filterMine = prefs.getString('$key.mine') ?? '';
    });
  }

  Future<void> _saveBucketPreferences() async {
    final key = _bucketPreferenceKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('$key.view', _viewMode),
      prefs.setString('$key.sort', _sortMode),
      prefs.setBool('$key.asc', _sortAscending),
      prefs.setString('$key.city', _filterCity),
      prefs.setString('$key.category', _filterCategory),
      prefs.setString('$key.priority', _filterPriority),
      prefs.setString('$key.voting', _filterVoting),
      prefs.setString('$key.mine', _filterMine),
    ]);
  }
}
