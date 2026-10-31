// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodVote on _TripBucketListPageState {
  Future<void> _vote(BucketListItem item, BucketPriority priority) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _pendingVoteIds.contains(item.id)) {
      return;
    }
    final previous = Map<String, BucketPriority>.from(
      _itemVotes[item.id] ?? const <String, BucketPriority>{},
    );
    if (previous[uid] == priority) {
      return;
    }
    setState(() {
      _pendingVoteIds.add(item.id);
      _itemVotes[item.id] = {...previous, uid: priority};
    });
    try {
      await _votes.saveMyVote(
        tripId: widget.tripId,
        activityId: item.id,
        priority: priority,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _itemVotes[item.id] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Voto non salvato. Riprova.', 'Vote not saved. Please retry.'),
          ),
        ),
      );
    } finally {
      _pendingVoteIds.remove(item.id);
    }
  }
}
