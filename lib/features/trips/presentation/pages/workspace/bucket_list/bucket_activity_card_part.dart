part of 'trip_bucket_list_page.dart';

extension _BucketActivityCard on _TripBucketListPageState {
  Widget _buildActivityCard(BucketListItem item) {
    final votes = _itemVotes[item.id] ?? const <String, BucketPriority>{};
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final myVote = votes[uid];

    var total = 0;
    var count = 0;

    for (final memberUid in _members) {
      final vote = votes[memberUid];
      if (vote != null) {
        total += vote.points;
        count++;
      }
    }

    final average = count == 0 ? null : total / count;
    final groupPriority = average == null
        ? '-'
        : average >= 8.5
        ? 'SS'
        : average >= 6
        ? 'S'
        : average >= 3
        ? 'A'
        : 'B';

    final allVoted = _members.isNotEmpty && count == _members.length;

    const background = Color(0xFF211914);
    const border = Color(0xFF503629);
    const cream = Color(0xFFF5E9DA);
    const muted = Color(0xFFC4B2A3);
    const amber = Color(0xFFF2B45C);
    const vermilion = Color(0xFFD66A42);

    Widget infoPill(IconData icon, String label, {Color? foreground}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF30241D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground ?? muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground ?? cream,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Widget photoArea({required bool compact}) {
      final placeId = item.googlePlaceId?.trim();
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: placeId == null || placeId.isEmpty
            ? null
            : () async {
                final uri = Uri.https('www.google.com', '/maps/search/', {
                  'api': '1',
                  'query': item.name,
                  'query_place_id': placeId,
                });
                bool opened;
                try {
                  opened = await launchUrl(
                    uri,
                    mode: LaunchMode.platformDefault,
                  );
                } catch (_) {
                  opened = false;
                }
                if (!mounted) {
                  return;
                }
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _t(
                          'Impossibile aprire Google Maps.',
                          'Could not open Google Maps.',
                        ),
                      ),
                    ),
                  );
                }
              },
        child: BucketPlacePhoto(
          placeId: item.googlePlaceId,
          height: compact ? 154 : 224,
          languageCode: Localizations.localeOf(context).languageCode,
        ),
      );
    }

    Widget details() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: cream,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              IconButton(
                tooltip: _t('Modifica attività', 'Edit activity'),
                onPressed: () => _openEditor(item),
                icon: const Icon(Icons.edit_outlined, color: amber),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.city} · ${item.country}',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              infoPill(
                Icons.category_outlined,
                item.customCategory ?? _typeLabel(item.type),
              ),
              if (item.durationMinutes != null)
                infoPill(
                  Icons.schedule_outlined,
                  '${item.durationMinutes} min',
                ),
              infoPill(
                Icons.workspace_premium_outlined,
                '${_t('Gruppo', 'Group')} $groupPriority',
                foreground: amber,
              ),
              infoPill(
                Icons.groups_outlined,
                '$count/${_members.length} ${_t('voti', 'votes')}',
              ),
            ],
          ),
          if (item.usefulLinks.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 5,
              children: [
                for (final link in item.usefulLinks)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 15),
                    label: Text(
                      Uri.tryParse(link)?.host ?? _t('Apri link', 'Open link'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // AMATERASU_USEFUL_LINK_DESKTOP_V1
                    onPressed: () async {
                      final uri = Uri.tryParse(link.trim());

                      if (uri == null ||
                          (uri.scheme != 'https' && uri.scheme != 'http') ||
                          uri.host.isEmpty) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _t(
                                'Il link non è valido.',
                                'The link is invalid.',
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      bool opened = false;

                      try {
                        opened = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                          webOnlyWindowName: '_blank',
                        );
                      } catch (_) {
                        opened = false;
                      }

                      if (!mounted || opened) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t(
                              'Impossibile aprire il link. '
                                  'Puoi copiarlo e aprirlo nel browser.',
                              'Could not open the link. '
                                  'You can copy it and open it '
                                  'in your browser.',
                            ),
                          ),
                          action: SnackBarAction(
                            label: _t('Copia link', 'Copy link'),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: uri.toString()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          if (item.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.notes.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  _t('La tua priorità', 'Your priority'),
                  style: const TextStyle(
                    color: cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                average == null
                    ? _t('Nessun voto', 'No votes')
                    : '${_t('Media', 'Average')} ${average.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  color: amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: BucketPriority.values.map((priority) {
              final selected = priority == myVote;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Material(
                    color: selected ? vermilion : const Color(0xFF352820),
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => _vote(item, priority),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          priority.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                allVoted ? Icons.check_circle_outline : Icons.hourglass_empty,
                size: 16,
                color: allVoted ? amber : muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  allVoted
                      ? _t('Tutti hanno votato', 'Everyone has voted')
                      : _t(
                          'In attesa degli altri viaggiatori',
                          'Waiting for other travelers',
                        ),
                  style: TextStyle(
                    color: allVoted ? amber : muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.event_note_outlined, size: 17),
              label: Text(_t('Aggiungi a itinerario', 'Add to itinerary')),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 620;

            if (horizontal) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: constraints.maxWidth * 0.35,
                    child: photoArea(compact: false),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: details()),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photoArea(compact: true),
                const SizedBox(height: 14),
                details(),
              ],
            );
          },
        ),
      ),
    );
  }
}
