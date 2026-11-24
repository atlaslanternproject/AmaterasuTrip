// Scheda "Valigia" della pagina Shopping: voci da portare per persona (o
// per tutti), filtri per persona e da mettere / già in valigia, tre viste
// ricordate, spunta dalla card, editor ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_shopping_editors.dart';
import 'widgets/trip_shopping_entries.dart';

class TripPackingTab extends ConsumerStatefulWidget {
  const TripPackingTab({super.key, required this.tripId, required this.tabs});

  final String tripId;
  final Widget tabs;

  @override
  ConsumerState<TripPackingTab> createState() => _TripPackingTabState();
}

class _TripPackingTabState extends ConsumerState<TripPackingTab>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'packingItems';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripPackingStoreProvider).currentUid;

  Future<void> _edit([TripPackingItem? initial]) async {
    final store = ref.read(tripPackingStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripPackingEditor(
        tripId: widget.tripId,
        authorUid: uid,
        memberNames: ref.read(tripStaysMemberNamesProvider(widget.tripId)),
        initial: initial,
        onSave: (item) =>
            initial == null ? store.create(item) : store.update(item),
      ),
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaved)));
    }
  }

  void _saveFailed() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.sectionsSaveError)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final store = ref.watch(tripPackingStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;

    return TripSectionScaffold<TripPackingItem>(
      tripId: tripId,
      keyPrefix: 'packing',
      title: l10n.tripShoppingTitle,
      addLabel: l10n.packingAdd,
      onAdd: _edit,
      top: widget.tabs,
      items: ref.watch(tripPackingProvider(tripId)),
      emptyIcon: Icons.luggage_rounded,
      emptyText: l10n.packingEmpty,
      body: (items) {
        final shown = _filter.apply(
          items,
          today: DateTime.now(),
          dayOf: (_) => null,
          statusOf: (i) => i.packed ? 'done' : 'todo',
          kindOf: (i) => i.personUid ?? 'everyone',
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'packing',
              onClear: () => setState(() => _filter = _filter.cleared()),
              shown: shown.length,
              total: items.length,
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                statuses: [
                  ('todo', l10n.packingToPack),
                  ('done', l10n.packingPacked),
                ],
                kinds: [
                  ('everyone', l10n.packingForEveryone),
                  for (final e in names.entries) (e.key, e.value),
                ],
                dated: false,
                kindTitle: l10n.shoppingFor,
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripPackingItem>(
                keyPrefix: 'packing',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (i) => tripPackingEntry(context, i, nameOf),
                extraOf: (i) => TripSectionDoneBox(
                  key: Key('packing-done-${i.id}'),
                  label: l10n.packingPacked,
                  value: i.packed,
                  onChanged: () => store
                      .update(i.toggled())
                      .catchError((Object _) => _saveFailed()),
                ),
                onEdit: _edit,
                canDelete: (i) =>
                    uid != null && (uid == i.createdByUid || uid == ownerUid),
                onDelete: (i) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'packing',
                  name: i.name,
                  delete: () => store.delete(i),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
