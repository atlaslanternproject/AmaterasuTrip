part of 'trip_bucket_list_page.dart';

extension _BucketActivityDeletionRequest on _TripBucketListPageState {
  Future<bool> _confirmDeletionRequest(
    BuildContext dialogContext,
    BucketListItem activity,
  ) async {
    final first = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF211914),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t('Richiedere l’eliminazione?', 'Request deletion?')),
        content: Text(
          _t(
            'Stai per proporre l’eliminazione di questa attività. '
                'Non sarà rimossa immediatamente: servirà la revisione '
                'del proprietario del viaggio.',
            'You are about to request deletion of this activity. '
                'It will not be deleted immediately: the trip owner '
                'must review the request.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t('Continua', 'Continue')),
          ),
        ],
      ),
    );
    if (first != true || !dialogContext.mounted) return false;

    final confirmation = TextEditingController();
    bool second = false;
    try {
      second =
          await showDialog<bool>(
            context: dialogContext,
            builder: (context) => StatefulBuilder(
              builder: (context, refresh) => AlertDialog(
                backgroundColor: const Color(0xFF211914),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(_t('Conferma la richiesta', 'Confirm the request')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Scrivi ELIMINA per confermare.',
                        'Type DELETE to confirm.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmation,
                      autofocus: true,
                      onChanged: (_) => refresh(() {}),
                      decoration: InputDecoration(
                        hintText: _t('ELIMINA', 'DELETE'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(_t('Annulla', 'Cancel')),
                  ),
                  FilledButton(
                    onPressed:
                        confirmation.text.trim() == _t('ELIMINA', 'DELETE')
                        ? () => Navigator.pop(context, true)
                        : null,
                    child: Text(_t('Invia richiesta', 'Send request')),
                  ),
                ],
              ),
            ),
          ) ??
          false;
    } finally {
      confirmation.dispose();
    }
    if (!second || !dialogContext.mounted) return false;
    try {
      final repository = BucketDeletionRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );
      await repository.requestDeletion(
        tripId: widget.tripId,
        activityId: activity.id,
      );
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Richiesta inviata. L’attività rimane visibile in attesa di revisione.',
                'Request sent. The activity remains visible pending review.',
              ),
            ),
          ),
        );
      }
      return true;
    } catch (_) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Richiesta non riuscita o già presente. Verifica le autorizzazioni.',
                'Request failed or already exists. Check your permissions.',
              ),
            ),
          ),
        );
      }
      return false;
    }
  }
}
