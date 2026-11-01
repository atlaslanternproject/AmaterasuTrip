part of 'trip_bucket_list_page.dart';

class _BucketPendingGroup {
  const _BucketPendingGroup(this.activity, this.requests);

  final BucketListItem activity;
  final List<BucketDeletionRequest> requests;
}

extension _BucketDeletionReview on _TripBucketListPageState {
  Future<List<_BucketPendingGroup>> _loadPendingDeletionGroups() async {
    if (_bucketOwnerUid != FirebaseAuth.instance.currentUser?.uid) {
      return const [];
    }

    final repository = BucketDeletionRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );

    final results = await Future.wait(
      _items.map((activity) async {
        final requests = await repository.getPendingRequests(
          tripId: widget.tripId,
          activityId: activity.id,
        );

        final pending = requests
            .where((request) => request.isPending)
            .toList(growable: false);

        if (pending.isEmpty) return null;

        return _BucketPendingGroup(activity, pending);
      }),
    );

    return results.whereType<_BucketPendingGroup>().toList(growable: false);
  }

  Widget _pendingDeletionEntry() {
    if (_bucketOwnerUid != FirebaseAuth.instance.currentUser?.uid) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<_BucketPendingGroup>>(
      future: _pendingDeletionFuture,
      builder: (context, snapshot) {
        final groups = snapshot.data;

        if (groups == null || groups.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: const Color(0xFF281D17),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDeletionReview(groups),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFFE8A552),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Richieste da gestire', 'Requests to review'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF2E7D5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t(
                              '${groups.length} attività con eliminazione proposta',
                              '${groups.length} activities proposed for deletion',
                            ),
                            style: const TextStyle(color: Color(0xFFB7A99B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFE8A552)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDeletionReview(List<_BucketPendingGroup> groups) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF211914),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('Richieste di eliminazione', 'Deletion requests'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF2E7D5),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final group = groups[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30231C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.activity.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF2E7D5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.activity.city,
                          style: const TextStyle(color: Color(0xFFB7A99B)),
                        ),
                        const SizedBox(height: 12),
                        for (final request in group.requests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${request.requestedByUid}: '
                              '${request.reason.isEmpty ? _t('Nessuna motivazione', 'No reason provided') : request.reason}',
                              style: const TextStyle(color: Color(0xFFF2E7D5)),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _decidePendingDeletion(group, approve: false);
                                },
                                child: Text(_t('Rifiuta', 'Reject')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _decidePendingDeletion(group, approve: true);
                                },
                                child: Text(_t('Approva', 'Approve')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _decidePendingDeletion(
    _BucketPendingGroup group, {
    required bool approve,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF211914),
        title: Text(
          approve
              ? _t('Eliminare definitivamente?', 'Delete permanently?')
              : _t('Rifiutare la richiesta?', 'Reject the request?'),
        ),
        content: Text(
          approve
              ? _t(
                  'L’attività "${group.activity.name}" e i suoi voti '
                      'saranno eliminati definitivamente.',
                  'The activity "${group.activity.name}" and its votes '
                      'will be permanently deleted.',
                )
              : _t(
                  'L’attività rimarrà nella Bucket List.',
                  'The activity will remain in the Bucket List.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              approve
                  ? _t('Elimina definitivamente', 'Delete permanently')
                  : _t('Conferma rifiuto', 'Confirm rejection'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (approve) {
        final callable = FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        ).httpsCallable('approveBucketActivityDeletion');

        await callable.call(<String, dynamic>{
          'tripId': widget.tripId,
          'activityId': group.activity.id,
          'requestId': group.requests.first.id,
        });
      } else {
        final repository = BucketDeletionRepository(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        );

        for (final request in group.requests) {
          await repository.reviewRequest(
            tripId: widget.tripId,
            activityId: group.activity.id,
            requestId: request.id,
            approve: false,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? _t('Attività eliminata.', 'Activity deleted.')
                : _t('Richiesta rifiutata.', 'Request rejected.'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Operazione non completata. Aggiorna e riprova.',
              'Operation not completed. Refresh and retry.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) await _refresh();
    }
  }
}
