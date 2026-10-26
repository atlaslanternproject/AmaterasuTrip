import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_activity_repository.dart';
import 'package:amaterasutrip/features/trips/bucket_list/data/bucket_vote_repository.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_priority.dart';

class TripBucketListPage extends StatefulWidget {
  const TripBucketListPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripBucketListPage> createState() => _TripBucketListPageState();
}

class _TripBucketListPageState extends State<TripBucketListPage> {
  late final BucketActivityRepository _activities;
  late final BucketVoteRepository _votes;

  final List<BucketListItem> _items = [];
  final Map<String, Map<String, BucketPriority>> _itemVotes = {};

  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  List<String> _members = [];
  bool _loading = true;
  bool _busy = false;
  bool _hasMore = false;
  String? _error;

  bool get _it =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'it';

  String _t(String it, String en) => _it ? it : en;

  @override
  void initState() {
    super.initState();

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    _activities = BucketActivityRepository(firestore, auth);
    _votes = BucketVoteRepository(firestore, auth);

    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
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

  Future<void> _saveActivity({
    BucketListItem? existing,
    required String name,
    required String city,
    required String country,
    required BucketItemType type,
    required int? duration,
    required String notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw StateError('Authentication required');
    }

    final now = DateTime.now().toUtc();

    if (existing == null) {
      final id = _activities.newActivityId(widget.tripId);

      final item = BucketListItem(
        id: id,
        tripId: widget.tripId,
        name: name.trim(),
        city: city.trim(),
        country: country.trim(),
        type: type,
        durationMinutes: duration,
        notes: notes.trim(),
        createdByUid: uid,
        createdAt: now,
        updatedAt: now,
      );

      await _activities.create(item);
    } else {
      final updated = BucketListItem(
        id: existing.id,
        tripId: existing.tripId,
        name: name.trim(),
        city: city.trim(),
        country: country.trim(),
        type: type,
        durationMinutes: duration,
        notes: notes.trim(),
        usefulLinks: existing.usefulLinks,
        googlePlaceId: existing.googlePlaceId,
        address: existing.address,
        latitude: existing.latitude,
        longitude: existing.longitude,
        createdByUid: existing.createdByUid,
        createdAt: existing.createdAt,
        updatedAt: now.isAfter(existing.updatedAt)
            ? now
            : existing.updatedAt.add(const Duration(milliseconds: 1)),
      );

      await _activities.update(updated);
    }
  }

  Future<void> _openEditor([BucketListItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final country = TextEditingController(text: existing?.country ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final duration = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '',
    );

    var type = existing?.type ?? BucketItemType.attraction;
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  existing == null
                      ? _t('Nuova attività', 'New activity')
                      : _t('Modifica attività', 'Edit activity'),
                ),
                content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: name,
                          maxLength: 200,
                          decoration: InputDecoration(
                            labelText: _t('Nome *', 'Name *'),
                          ),
                        ),
                        TextField(
                          controller: city,
                          maxLength: 150,
                          decoration: InputDecoration(
                            labelText: _t('Città *', 'City *'),
                          ),
                        ),
                        TextField(
                          controller: country,
                          maxLength: 150,
                          decoration: InputDecoration(
                            labelText: _t('Paese *', 'Country *'),
                          ),
                        ),
                        DropdownButtonFormField<BucketItemType>(
                          initialValue: type,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _t('Categoria', 'Category'),
                          ),
                          items: BucketItemType.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(_typeLabel(value)),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(() => type = value);
                                  }
                                },
                        ),
                        TextField(
                          controller: duration,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _t(
                              'Durata in minuti (facoltativa)',
                              'Duration in minutes (optional)',
                            ),
                          ),
                        ),
                        TextField(
                          controller: notes,
                          maxLines: 3,
                          maxLength: 10000,
                          decoration: InputDecoration(
                            labelText: _t('Note', 'Notes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: Text(_t('Annulla', 'Cancel')),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (name.text.trim().isEmpty ||
                                city.text.trim().isEmpty ||
                                country.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _t(
                                      'Compila nome, città e paese.',
                                      'Enter name, city and country.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            final durationText = duration.text.trim();
                            final minutes = durationText.isEmpty
                                ? null
                                : int.tryParse(durationText);

                            if (durationText.isNotEmpty &&
                                (minutes == null ||
                                    minutes <= 0 ||
                                    minutes > 10080)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _t(
                                      'Inserisci una durata valida.',
                                      'Enter a valid duration.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => saving = true);

                            try {
                              await _saveActivity(
                                existing: existing,
                                name: name.text,
                                city: city.text,
                                country: country.text,
                                type: type,
                                duration: minutes,
                                notes: notes.text,
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              await _refresh();
                            } catch (error) {
                              if (dialogContext.mounted) {
                                setDialogState(() => saving = false);
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(content: Text('$error')),
                                );
                              }
                            }
                          },
                    child: Text(
                      saving
                          ? _t('Salvataggio...', 'Saving...')
                          : _t('Salva', 'Save'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Keep controllers alive until the dialog transition completes.
      // Disposal is handled after this route has closed.
      name.dispose();
      city.dispose();
      country.dispose();
      notes.dispose();
      duration.dispose();
    }
  }

  String _typeLabel(BucketItemType value) {
    switch (value) {
      case BucketItemType.attraction:
        return _t('Attrazione', 'Attraction');
      case BucketItemType.area:
        return _t('Zona', 'Area');
      case BucketItemType.city:
        return _t('Città', 'City');
      case BucketItemType.experience:
        return _t('Esperienza', 'Experience');
      case BucketItemType.event:
        return _t('Evento', 'Event');
      case BucketItemType.other:
        return _t('Altro', 'Other');
    }
  }

  Future<void> _vote(BucketListItem item, BucketPriority priority) async {
    try {
      await _votes.saveMyVote(
        tripId: widget.tripId,
        activityId: item.id,
        priority: priority,
      );

      final votes = await _votes.fetchVotes(
        tripId: widget.tripId,
        activityId: item.id,
      );

      if (mounted) {
        setState(() => _itemVotes[item.id] = votes);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_t('Voto non salvato:', 'Vote not saved:')} $error',
            ),
          ),
        );
      }
    }
  }

  Widget _buildActivityCard(BucketListItem item) {
    final votes = _itemVotes[item.id] ?? {};
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

    String groupPriority = '-';

    if (average != null) {
      groupPriority = average >= 8.5
          ? 'SS'
          : average >= 6
          ? 'S'
          : average >= 3
          ? 'A'
          : 'B';
    }

    final allVoted = _members.isNotEmpty && count == _members.length;

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.city} · ${item.country}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _t('Modifica', 'Edit'),
                  onPressed: () => _openEditor(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text(_typeLabel(item.type))),
                if (item.durationMinutes != null)
                  Chip(label: Text('${item.durationMinutes} min')),
                Chip(
                  label: Text(
                    '${_t('Voti', 'Votes')}: $count/${_members.length}',
                  ),
                ),
                Chip(label: Text('${_t('Gruppo', 'Group')}: $groupPriority')),
              ],
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.notes),
            ],
            const SizedBox(height: 12),
            Text(
              _t('La tua priorità', 'Your priority'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BucketPriority.values.map((priority) {
                final selected = priority == myVote;

                return ChoiceChip(
                  label: Text(priority.name.toUpperCase()),
                  selected: selected,
                  selectedColor: colorScheme.primaryContainer,
                  onSelected: (_) => _vote(item, priority),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              average == null
                  ? _t('Nessun voto', 'No votes yet')
                  : '${_t('Media', 'Average')}: ${average.toStringAsFixed(1)}/10',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!allVoted)
              Text(
                _t(
                  'In attesa dei voti di tutti i viaggiatori',
                  'Waiting for every traveler to vote',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (allVoted)
              Text(
                _t('Tutti hanno votato', 'Everyone has voted'),
                style: TextStyle(color: colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _t('Indietro', 'Back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips/${widget.tripId}'),
        ),
        title: const Text('Bucket List'),
        actions: [
          IconButton(
            tooltip: _t('Aggiorna', 'Refresh'),
            onPressed: _loading || _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(_t('Nuova attività', 'New activity')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    _t(
                      'Organizza i luoghi da visitare e vota con i tuoi compagni di viaggio.',
                      'Save places to visit and vote with your travel group.',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          '${_t('Errore', 'Error')}: $_error',
                        ),
                      ),
                    ),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          _t(
                            'Nessuna attività. Aggiungi il primo luogo!',
                            'No activities yet. Add your first place!',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  for (final item in _items) _buildActivityCard(item),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _loadMore,
                          child: Text(
                            _busy
                                ? _t('Caricamento...', 'Loading...')
                                : _t('Carica altre', 'Load more'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
