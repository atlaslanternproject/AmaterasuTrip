// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodRefresh on _TripBucketListPageState {
  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
      _totalCountFuture = _readBucketTotal();
      _loading = true;
      _busy = false;
      _error = null;
      _items.clear();
      _itemVotes.clear();
      _cursor = null;
      _hasMore = false;
    });

    try {
      final trip = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      final data = trip.data();

      if (data == null) {
        throw StateError('Trip not found');
      }

      final ids = <String>{};
      final owner = data['ownerUid'];

      if (owner is String && owner.isNotEmpty) {
        ids.add(owner);
      }

      final rawMembers = data['memberUids'];

      if (rawMembers is List) {
        ids.addAll(
          rawMembers.whereType<String>().where((uid) => uid.isNotEmpty),
        );
      }

      if (!mounted) return;

      setState(() => _members = ids.toList(growable: false));

      await _loadMore();

      var loadedPages = 1;

      while (mounted && _hasMore) {
        if (_error != null) {
          throw StateError('Bucket List loading interrupted');
        }

        final previousCount = _items.length;
        await _loadMore();

        if (_error != null || _items.length <= previousCount) {
          throw StateError('Bucket List pagination stopped unexpectedly');
        }

        loadedPages++;

        if (loadedPages > 200) {
          throw StateError('Bucket List pagination safety limit reached');
        }
      }

      await _loadCategories();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
