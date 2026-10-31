// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodLoadMore on _TripBucketListPageState {
  Future<void> _loadMore() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final page = await _activities.fetchPage(
        tripId: widget.tripId,
        after: _cursor,
      );

      final voteEntries = await Future.wait(
        page.items.map(
          (item) =>
              _votes.fetchVotes(tripId: widget.tripId, activityId: item.id),
        ),
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);

        for (var i = 0; i < page.items.length; i++) {
          _itemVotes[page.items[i].id] = voteEntries[i];
        }

        _cursor = page.lastDocument;
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
