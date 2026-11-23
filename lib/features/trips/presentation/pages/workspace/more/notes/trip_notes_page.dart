// Pagina Note del viaggio: note condivise e proprie private, fissate in
// alto, checklist spuntabili nella card, filtro condivise/private, tre viste
// ricordate, editor con modello "Info utili" ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_note_editor.dart';
import 'widgets/trip_note_entry.dart';

class TripNotesPage extends ConsumerStatefulWidget {
  const TripNotesPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripNotesPage> createState() => _TripNotesPageState();
}

class _TripNotesPageState extends ConsumerState<TripNotesPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'notes';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripNotesStoreProvider).currentUid;

  Future<void> _edit([TripNote? initial]) async {
    final store = ref.read(tripNotesStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripNoteEditor(
        tripId: widget.tripId,
        authorUid: uid,
        initial: initial,
        onSave: (note) =>
            initial == null ? store.create(note) : store.update(note),
      ),
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaved)));
    }
  }

  Future<void> _toggle(TripNote note, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final items = [...note.checklist];
    items[index] = items[index].toggled();
    try {
      await ref.read(tripNotesStoreProvider).update(note.withChecklist(items));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final store = ref.watch(tripNotesStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));

    return TripSectionScaffold<TripNote>(
      tripId: tripId,
      keyPrefix: 'note',
      title: l10n.tripNotesTitle,
      addLabel: l10n.noteAdd,
      onAdd: _edit,
      items: ref.watch(tripNotesProvider(tripId)),
      emptyIcon: Icons.sticky_note_2_rounded,
      emptyText: l10n.noteEmpty,
      body: (items) {
        final shown =
            _filter.apply(
              items,
              today: DateTime.now(),
              dayOf: (_) => null,
              kindOf: (n) => n.isPrivate ? 'private' : 'shared',
            )..sort((a, b) {
              if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            });
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'note',
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                kinds: [
                  ('shared', l10n.noteShared),
                  ('private', l10n.notePrivate),
                ],
                dated: false,
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripNote>(
                keyPrefix: 'note',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (n) => tripNoteEntry(context, n),
                extraOf: (n) => TripNoteChecklist(
                  note: n,
                  onToggle: (index) => _toggle(n, index),
                ),
                onEdit: _edit,
                canDelete: (n) =>
                    uid != null &&
                    (uid == n.createdByUid ||
                        (!n.isPrivate && uid == ownerUid)),
                onDelete: (n) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'note',
                  name: n.title,
                  delete: () => store.delete(n),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
