// Pagina Ricordi del viaggio: diario per giorno (valutazione, momento del
// giorno, testo, autore) e link agli album esterni; filtro diario/album,
// ordine per giorno, tre viste ricordate, editor ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_memory_editor.dart';
import 'widgets/trip_memory_entry.dart';

class TripMemoriesPage extends ConsumerStatefulWidget {
  const TripMemoriesPage({
    super.key,
    required this.tripId,
    this.launch,
    this.today,
  });

  final String tripId;
  final AmaterasuLaunch? launch;
  final DateTime? today;

  @override
  ConsumerState<TripMemoriesPage> createState() => _TripMemoriesPageState();
}

class _TripMemoriesPageState extends ConsumerState<TripMemoriesPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'memories';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripMemoriesStoreProvider).currentUid;

  Future<void> _edit([TripMemory? initial]) async {
    final store = ref.read(tripMemoriesStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripMemoryEditor(
        tripId: widget.tripId,
        authorUid: uid,
        initial: initial,
        today: widget.today,
        onSave: (item) =>
            initial == null ? store.create(item) : store.update(item),
      ),
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final store = ref.watch(tripMemoriesStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;

    return TripSectionScaffold<TripMemory>(
      tripId: tripId,
      keyPrefix: 'memory',
      title: l10n.tripMemoriesTitle,
      addLabel: l10n.memoryAdd,
      onAdd: _edit,
      items: ref.watch(tripMemoriesProvider(tripId)),
      emptyIcon: Icons.auto_stories_rounded,
      emptyText: l10n.memoryEmpty,
      body: (items) {
        final shown = _filter.apply(
          items,
          today: widget.today ?? DateTime.now(),
          dayOf: (m) => m.date,
          kindOf: (m) => m.kind.name,
        );
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'memory',
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                kinds: [('day', l10n.memoryDiary), ('album', l10n.memoryAlbum)],
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripMemory>(
                keyPrefix: 'memory',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (m) => tripMemoryEntry(context, m, nameOf),
                onEdit: _edit,
                canDelete: (m) =>
                    uid != null && (uid == m.createdByUid || uid == ownerUid),
                onDelete: (m) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'memory',
                  name: tripMemoryEntry(context, m, nameOf).title,
                  delete: () => store.delete(m),
                ),
                launch: widget.launch,
              ),
            ),
          ],
        );
      },
    );
  }
}
