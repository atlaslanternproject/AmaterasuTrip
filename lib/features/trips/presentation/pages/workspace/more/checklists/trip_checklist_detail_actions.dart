// Parte di trip_checklist_detail_page.dart: azioni della lista (menu con
// azzera spunte, duplica, stampa, esporta), filtri, nuove voci e categorie,
// modifica di una voce. Gli errori di salvataggio mostrano un messaggio.

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_checklist_detail_page.dart';

extension _TripChecklistDetailActions on _TripChecklistDetailPageState {
  void _run(Future<void> action) => action.catchError((Object _) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.sectionsSaveError)),
    );
  });

  void _addEntry(TripChecklist list, String category, String text) {
    final order = list.entriesOf(category).length;
    _run(
      ref
          .read(tripChecklistEntriesProvider)
          .save(
            list,
            TripChecklistEntry(
              id: TripChecklistTools.newId(),
              text: text,
              category: category,
              order: order,
            ),
          ),
    );
  }

  Future<void> _editEntry(
    TripChecklist list,
    TripChecklistEntry entry,
    Map<String, String> names,
  ) async {
    final result = await showTripChecklistEntrySheet(
      context,
      entry: entry,
      categories: list.shownCategories,
      memberNames: names,
    );
    if (result == null) return;
    final entries = ref.read(tripChecklistEntriesProvider);
    final edited = result.entry;
    if (result.delete) {
      _run(entries.remove(list, entry.id));
    } else if (edited != null) {
      _run(entries.save(list, edited));
    }
  }

  Future<void> _addCategory(TripChecklist list, AppLocalizations l10n) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AmaterasuColors.surfaceCard,
        title: Text(l10n.checklistAddCategory),
        content: TextField(
          key: const Key('checklist-category-name'),
          controller: controller,
          autofocus: true,
          maxLength: 60,
        ),
        actions: [
          AmaterasuButton.tertiary(
            onPressed: () => Navigator.pop(dialogContext),
            label: l10n.sectionsCancel,
          ),
          AmaterasuButton.primary(
            key: const Key('checklist-category-save'),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            label: l10n.sectionsSave,
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || list.shownCategories.contains(name)) {
      return;
    }
    _run(
      ref.read(tripChecklistEntriesProvider).setCategories(list, [
        ...list.shownCategories,
        name,
      ]),
    );
  }

  void _openFilters(AppLocalizations l10n, Map<String, String> names) {
    showAmaterasuFilterSheet<(String, String)>(
      context,
      keyPrefix: 'checklist-entries',
      initial: (_state, _person),
      onChanged: (f) => setState(() {
        _state = f.$1;
        _person = f.$2;
      }),
      isActive: (f) => f.$1 != 'all' || f.$2 != 'all',
      cleared: (_) => ('all', 'all'),
      groupsOf: (f, update) => [
        AmaterasuFilterGroup(l10n.sectionsBlockStatus, [
          for (final (code, label) in [
            ('all', l10n.sectionsAll),
            ('todo', l10n.checklistTodo),
            ('done', l10n.checklistDone),
          ])
            AmaterasuFilterOption(
              key: 'checklist-entries-state-$code',
              label: label,
              selected: f.$1 == code,
              onTap: () => update((code, f.$2)),
            ),
        ]),
        AmaterasuFilterGroup(l10n.checklistAssignee, [
          for (final (code, label) in [
            ('all', l10n.sectionsAll),
            for (final e in names.entries) (e.key, e.value),
          ])
            AmaterasuFilterOption(
              key: 'checklist-entries-person-$code',
              label: label,
              selected: f.$2 == code,
              onTap: () => update((f.$1, code)),
            ),
        ]),
      ],
    );
  }

  Widget _menu(
    TripChecklist list,
    AppLocalizations l10n,
    String? Function(String?) nameOf,
  ) => PopupMenuButton<String>(
    key: const Key('checklist-actions'),
    tooltip: l10n.sectionsMore,
    color: AmaterasuColors.surfaceCard,
    iconColor: AmaterasuColors.textPrimary,
    onSelected: (action) async {
      final messenger = ScaffoldMessenger.of(context);
      switch (action) {
        case 'reset':
          _run(ref.read(tripChecklistEntriesProvider).resetAll(list));
        case 'duplicate':
          final store = ref.read(tripChecklistsStoreProvider);
          final uid = store.currentUid;
          if (uid == null) return;
          _run(
            store
                .create(
                  TripChecklistTools.duplicate(
                    list,
                    authorUid: uid,
                    title: l10n.checklistCopyOf(list.title),
                  ),
                )
                .then((_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.checklistDuplicated)),
                  );
                }),
          );
        case 'print':
          if (!amaterasuPrintHtml(TripChecklistTools.html(list, nameOf))) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.budgetExportError)),
            );
          }
        case 'csv':
          amaterasuDownloadText(
            'checklist.csv',
            'text/csv;charset=utf-8',
            TripChecklistTools.csv(
              list,
              nameOf,
              l10n.checklistCsvColumns.split('|'),
              l10n.restaurantFilterYes,
              l10n.restaurantFilterNo,
            ),
          );
      }
    },
    itemBuilder: (_) => [
      for (final (code, label) in [
        ('reset', l10n.checklistReset),
        ('duplicate', l10n.checklistDuplicate),
        ('print', l10n.checklistPrint),
        ('csv', l10n.checklistExport),
      ])
        PopupMenuItem(
          key: Key('checklist-action-$code'),
          value: code,
          child: Text(label),
        ),
    ],
  );
}
