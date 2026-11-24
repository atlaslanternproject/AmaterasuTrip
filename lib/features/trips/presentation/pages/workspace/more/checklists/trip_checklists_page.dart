// Pagina Checklist del viaggio: elenco delle liste (condivise e proprie
// personali) con avanzamento, tre viste ricordate, filtro condivise/
// personali, creazione da modello pronto e import della vecchia valigia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_checklist_editor.dart';
import 'widgets/trip_checklist_import.dart';
import 'widgets/trip_checklist_progress.dart';

class TripChecklistsPage extends ConsumerStatefulWidget {
  const TripChecklistsPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripChecklistsPage> createState() => _TripChecklistsPageState();
}

class _TripChecklistsPageState extends ConsumerState<TripChecklistsPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'checklists';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripChecklistsStoreProvider).currentUid;

  Future<void> _edit([TripChecklist? initial]) async {
    final store = ref.read(tripChecklistsStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripChecklistEditor(
        tripId: widget.tripId,
        authorUid: uid,
        initial: initial,
        onSave: (list) =>
            initial == null ? store.create(list) : store.update(list),
      ),
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaved)));
    }
  }

  TripSectionEntry _entry(TripChecklist list, AppLocalizations l10n) =>
      TripSectionEntry(
        id: list.id,
        icon: list.isPrivate
            ? Icons.lock_outline_rounded
            : Icons.checklist_rounded,
        title: list.title,
        highlight: l10n.checklistDoneOf(list.doneCount, list.entries.length),
        chips: [
          TripSectionChip(
            label: list.isPrivate ? l10n.checklistPersonal : l10n.noteShared,
            color: list.isPrivate
                ? AmaterasuColors.accentGold
                : AmaterasuColors.textSecondary,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final store = ref.watch(tripChecklistsStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    void open(TripChecklist list) =>
        context.go('/trips/$tripId/more/checklists/${list.id}');

    return TripSectionScaffold<TripChecklist>(
      tripId: tripId,
      keyPrefix: 'checklist',
      title: l10n.checklistTitle,
      addLabel: l10n.checklistAdd,
      onAdd: _edit,
      top: TripChecklistImport(tripId: tripId),
      items: ref.watch(tripChecklistsProvider(tripId)),
      emptyIcon: Icons.checklist_rounded,
      emptyText: l10n.checklistEmpty,
      body: (items) {
        final shown =
            _filter.apply(
              items,
              today: DateTime.now(),
              dayOf: (_) => null,
              kindOf: (l) => l.isPrivate ? 'private' : 'shared',
            )..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'checklist',
              onClear: () => setState(() => _filter = _filter.cleared()),
              shown: shown.length,
              total: items.length,
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                kinds: [
                  ('shared', l10n.noteShared),
                  ('private', l10n.checklistPersonal),
                ],
                kindTitle: l10n.noteFilterVisibility,
                dated: false,
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripChecklist>(
                keyPrefix: 'checklist',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (l) => _entry(l, l10n),
                extraOf: (l) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TripChecklistProgress(
                    done: l.doneCount,
                    total: l.entries.length,
                  ),
                ),
                onOpen: open,
                onEdit: _edit,
                canDelete: (l) =>
                    uid != null &&
                    (uid == l.createdByUid ||
                        (!l.isPrivate && uid == ownerUid)),
                onDelete: (l) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'checklist',
                  name: l.title,
                  delete: () => store.delete(l),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
