// ignore_for_file: invalid_use_of_protected_member
part of 'trip_bucket_list_page.dart';

extension _BucketMethodPageView on _TripBucketListPageState {
  Widget _renderBucketPage(BuildContext context) {
    const bg = Color(0xFF100C0A);
    const surface = Color(0xFF1A1512);
    const cream = Color(0xFFF2E7D5);
    const muted = Color(0xFFB7A99B);
    const orange = Color(0xFFFF7A3D);
    const gold = Color(0xFFE8A552);
    final cities = {
      ..._items.map((e) => e.city),
      if (_filterCity.isNotEmpty) _filterCity,
    }.toList()..sort();
    final cats =
        _items
            .map(
              (e) => e.customCategory?.isNotEmpty == true
                  ? e.customCategory!
                  : e.type.name,
            )
            .toSet()
            .union({if (_filterCategory.isNotEmpty) _filterCategory})
            .toList()
          ..sort();
    final visible = _visibleItems;

    Widget filter(
      String label,
      String value,
      List<DropdownMenuItem<String>> choices,
      ValueChanged<String?> change,
    ) {
      return SizedBox(
        width: 162,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey(label + value),
          initialValue: value,
          dropdownColor: surface,
          style: const TextStyle(color: cream, fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: muted),
            filled: true,
            fillColor: surface,
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF68402B)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: choices,
          onChanged: change,
        ),
      );
    }

    DropdownMenuItem<String> option(String value, String label) =>
        DropdownMenuItem(
          value: value,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );

    Widget brief(BucketListItem item, bool details) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final votes = _itemVotes[item.id] ?? const <String, BucketPriority>{};
      final average = _averageFor(item);
      final count = _members.where((m) => votes.containsKey(m)).length;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF68402B), width: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!details)
                  SizedBox(
                    width: 92,
                    height: 94,
                    child: InkWell(
                      onTap: item.googlePlaceId?.isNotEmpty == true
                          ? () => launchUrl(
                              Uri.https('www.google.com', '/maps/search/', {
                                'api': '1',
                                'query': item.name,
                                'query_place_id': item.googlePlaceId!,
                              }),
                              mode: LaunchMode.platformDefault,
                            )
                          : null,
                      child: BucketPlacePhoto(
                        placeId: item.googlePlaceId,
                        height: 94,
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                      ),
                    ),
                  ),
                if (!details) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.city,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.customCategory?.trim().isNotEmpty == true
                            ? item.customCategory!
                            : _typeLabel(item.type),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_t('Gruppo', 'Group')}: ${_priorityFor(item)}  ·  '
                        '${_t('Media', 'Average')}: ${count == 0 ? '-' : average.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: _t('Modifica', 'Edit'),
                  onPressed: () => _openEditor(item),
                  icon: const Icon(Icons.edit_outlined, color: gold),
                ),
              ],
            ),
            ...[
              const SizedBox(height: 10),
              Text(
                _t('La tua priorità', 'Your priority'),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final priority in BucketPriority.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: votes[uid] == priority
                                ? orange
                                : const Color(0xFF36271E),
                            foregroundColor: cream,
                            minimumSize: const Size(0, 38),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _vote(item, priority),
                          child: Text(priority.name.toUpperCase()),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    Widget bucketFilterPanel(void Function(VoidCallback) update) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
        decoration: const BoxDecoration(
          color: surface,
          border: Border(
            bottom: BorderSide(color: Color(0xFF503629), width: 1.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: _t(
                  'Cerca attività, città, categoria...',
                  'Search activity, city, category...',
                ),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _filterSearch = value);
                update(() {});
                if (value.trim().isNotEmpty) _loadAllForSearch();
              },
            ),
            const SizedBox(height: 10),
            if (_searchLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _t('Caricamento attività...', 'Loading activities...'),
                ),
              ),
            SizedBox(
              height: 270,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    filter(
                      _t('Città', 'City'),
                      _filterCity,
                      [
                        option('', _t('Tutte', 'All')),
                        for (final city in cities) option(city, city),
                      ],
                      (value) => update(() => _filterCity = value ?? ''),
                    ),
                    filter(
                      _t('Categoria', 'Category'),
                      _filterCategory,
                      [
                        option('', _t('Tutte', 'All')),
                        for (final category in cats)
                          option(
                            category,
                            BucketItemType.values.any(
                                  (type) => type.name == category,
                                )
                                ? _typeLabel(
                                    BucketItemType.values.firstWhere(
                                      (type) => type.name == category,
                                    ),
                                  )
                                : category,
                          ),
                      ],
                      (value) => update(() => _filterCategory = value ?? ''),
                    ),
                    filter(
                      _t('Priorità', 'Priority'),
                      _filterPriority,
                      [
                        option('', _t('Tutte', 'All')),
                        for (final priority in ['SS', 'S', 'A', 'B', '-'])
                          option(priority, priority),
                      ],
                      (value) => update(() => _filterPriority = value ?? ''),
                    ),
                    filter(
                      _t('Votazioni', 'Votes'),
                      _filterVoting,
                      [
                        option('', _t('Tutte', 'All')),
                        option('complete', _t('Complete', 'Complete')),
                        option('pending', _t('In attesa', 'Pending')),
                      ],
                      (value) => update(() => _filterVoting = value ?? ''),
                    ),
                    filter(
                      _t('Il mio voto', 'My vote'),
                      _filterMine,
                      [
                        option('', _t('Tutte', 'All')),
                        option('voted', _t('Già votate', 'Voted')),
                        option('pending', _t('Da votare', 'To vote')),
                      ],
                      (value) => update(() => _filterMine = value ?? ''),
                    ),
                    filter(
                      _t('Ordina', 'Sort'),
                      _sortMode,
                      [
                        option(
                          'priority',
                          _t('Priorità gruppo', 'Group priority'),
                        ),
                        option('average', _t('Media voti', 'Average vote')),
                        option('interested', _t('Votanti', 'Voters')),
                        option('city', _t('Città', 'City')),
                        option('name', _t('Nome', 'Name')),
                        option('date', _t('Data creazione', 'Creation date')),
                      ],
                      (value) => update(() => _sortMode = value ?? 'priority'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('Direzione ordinamento', 'Sort direction'),
              style: const TextStyle(color: cream, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(_t('Crescente ↑', 'Ascending ↑')),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(_t('Decrescente ↓', 'Descending ↓')),
                ),
              ],
              selected: {_sortAscending},
              onSelectionChanged: (value) =>
                  update(() => _sortAscending = value.first),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                label: Text(
                  _t(
                    'Resetta filtri e ordinamento',
                    'Reset filters and sorting',
                  ),
                ),
                onPressed: () => update(() {
                  _filterCity = '';
                  _filterCategory = '';
                  _filterPriority = '';
                  _filterVoting = '';
                  _filterMine = '';
                  _filterSearch = '';
                  _sortMode = 'priority';
                  _sortAscending = false;
                }),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/trips/${widget.tripId}'),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: cream,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Bucket List',
                          style: const TextStyle(
                            color: cream,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _t('Aggiorna', 'Refresh'),
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh, color: cream),
                      ),

                      IconButton(
                        tooltip: _t(
                          'Filtri e ordinamento',
                          'Filters and sorting',
                        ),
                        icon: const Icon(Icons.tune_rounded, color: gold),
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: surface,
                            useSafeArea: true,
                            builder: (sheetContext) {
                              return StatefulBuilder(
                                builder: (sheetContext, setSheetState) {
                                  return FractionallySizedBox(
                                    heightFactor: 0.68,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _t(
                                                    'Filtri e ordinamento',
                                                    'Filters and sorting',
                                                  ),
                                                  style: const TextStyle(
                                                    color: cream,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    Navigator.pop(sheetContext),
                                                icon: const Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          bucketFilterPanel((change) {
                                            setState(change);
                                            setSheetState(() {});
                                            _saveBucketPreferences();
                                          }),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        tooltip: _t('Nuova attività', 'New activity'),
                        onPressed: () => _openEditor(),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                ),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'cards',
                        label: Text(_t('Card', 'Cards')),
                        icon: const Icon(Icons.grid_view),
                      ),
                      ButtonSegment(
                        value: 'list',
                        label: Text(_t('Elenco', 'List')),
                        icon: const Icon(Icons.view_list),
                      ),
                      ButtonSegment(
                        value: 'details',
                        label: Text(_t('Dettagli', 'Details')),
                        icon: const Icon(Icons.table_rows),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (values) => setState(() {
                      _viewMode = values.first;
                      _saveBucketPreferences();
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: RefreshIndicator(
                    color: orange,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                      children: [
                        FutureBuilder<int>(
                          future: _totalCountFuture,
                          builder: (context, snapshot) {
                            final total = snapshot.data;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                total == null
                                    ? _t(
                                        'Conteggio attività…',
                                        'Counting activities…',
                                      )
                                    : _t(
                                        '$total attività totali · ${visible.length} caricate',
                                        '$total total activities · ${visible.length} loaded',
                                      ),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                        if (_hasMore)
                          Text(
                            _t(
                              'Filtri applicati alle attività caricate.',
                              'Filters apply to loaded activities.',
                            ),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        if (_loading)
                          const Center(
                            child: CircularProgressIndicator(color: orange),
                          )
                        else ...[
                          if (_error != null)
                            Text(
                              _t(
                                'Errore nel caricamento. Riprova.',
                                'Load failed. Please retry.',
                              ),
                              style: const TextStyle(color: orange),
                            ),
                          for (final item in visible)
                            if (_viewMode == 'cards')
                              _buildActivityCard(item)
                            else
                              brief(item, _viewMode == 'details'),
                          if (visible.isEmpty && _error == null)
                            Text(
                              _t('Nessun risultato.', 'No results.'),
                              style: const TextStyle(color: muted),
                            ),
                          if (_hasMore)
                            Center(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _loadMore,
                                child: Text(
                                  _t(
                                    'Carica altre attività',
                                    'Load more activities',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
