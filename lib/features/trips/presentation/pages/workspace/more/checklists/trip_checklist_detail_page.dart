// Pagina di una checklist: avanzamento generale ("12 su 30"), filtri
// (da fare / fatte, persona) con la barra dei filtri condivisa, categorie a
// tendina con voci in linea e azioni (azzera spunte, duplica, stampa,
// esporta, nuova categoria). Le azioni stanno nel file part.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/files/amaterasu_files.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_bar.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_sheet.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_tools.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'widgets/trip_checklist_category.dart';
import 'widgets/trip_checklist_entry_sheet.dart';
import 'widgets/trip_checklist_progress.dart';

part 'trip_checklist_detail_actions.dart';

class TripChecklistDetailPage extends ConsumerStatefulWidget {
  const TripChecklistDetailPage({
    super.key,
    required this.tripId,
    required this.listId,
  });

  final String tripId;
  final String listId;

  @override
  ConsumerState<TripChecklistDetailPage> createState() =>
      _TripChecklistDetailPageState();
}

class _TripChecklistDetailPageState
    extends ConsumerState<TripChecklistDetailPage> {
  /// 'all', 'todo' or 'done'; [_person] 'all' or a uid.
  var _state = 'all';
  var _person = 'all';

  bool get _filtered => _state != 'all' || _person != 'all';

  bool _matches(TripChecklistEntry e) =>
      (_state == 'all' || (_state == 'done') == e.done) &&
      (_person == 'all' || e.assigneeUid == _person);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final lists = ref.watch(tripChecklistsProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    final list = lists.asData?.value
        .where((l) => l.id == widget.listId)
        .firstOrNull;
    String? nameOf(String? uid) =>
        uid == null ? null : (names[uid] ?? l10n.sectionsFormerMember);

    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.go('/trips/$tripId/more/checklists'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AmaterasuColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      list?.title ?? l10n.checklistTitle,
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (list != null) _menu(list, l10n, nameOf),
                ],
              ),
            ),
            Expanded(
              child: list == null
                  ? Center(
                      child: lists.isLoading
                          ? const CircularProgressIndicator()
                          : Text(l10n.sectionsLoadError),
                    )
                  : _body(list, l10n, names, nameOf),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    TripChecklist list,
    AppLocalizations l10n,
    Map<String, String> names,
    String? Function(String?) nameOf,
  ) {
    final categories = list.shownCategories;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          key: const Key('checklist-detail'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            TripChecklistProgress(
              done: list.doneCount,
              total: list.entries.length,
            ),
            const SizedBox(height: 10),
            AmaterasuFilterBar(
              keyPrefix: 'checklist-entries',
              activeCount:
                  (_state == 'all' ? 0 : 1) + (_person == 'all' ? 0 : 1),
              onOpen: () => _openFilters(l10n, names),
              onClear: () => setState(() {
                _state = 'all';
                _person = 'all';
              }),
              padding: const EdgeInsets.only(bottom: 10),
            ),
            for (final category in categories)
              TripChecklistCategory(
                name: category,
                all: list.entriesOf(category),
                shown: list.entriesOf(category).where(_matches).toList(),
                nameOf: nameOf,
                onToggle: (e) => _run(
                  ref
                      .read(tripChecklistEntriesProvider)
                      .setDone(list, e.id, !e.done),
                ),
                onQuantity: (e, q) => _run(
                  ref
                      .read(tripChecklistEntriesProvider)
                      .save(
                        list,
                        e.copyWith(quantity: q, clearQuantity: q == null),
                      ),
                ),
                onOpen: (e) => _editEntry(list, e, names),
                onAdd: (text) => _addEntry(list, category, text),
                onReorder: _filtered
                    ? null
                    : (ids) => _run(
                        ref
                            .read(tripChecklistEntriesProvider)
                            .reorder(list, ids),
                      ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('checklist-add-category'),
                onPressed: () => _addCategory(list, l10n),
                icon: const Icon(Icons.add),
                label: Text(l10n.checklistAddCategory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
