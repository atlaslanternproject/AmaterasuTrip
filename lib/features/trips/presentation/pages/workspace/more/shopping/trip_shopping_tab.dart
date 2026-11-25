// Scheda "Acquisti" della pagina Shopping: voci da comprare con filtri (da
// comprare / comprati, per chi), tre viste ricordate, "comprato" dalla card,
// editor, spesa collegata (categoria shopping) ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_priority.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_expense_actions.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_shopping_editors.dart';
import 'widgets/trip_shopping_entries.dart';

class TripShoppingTab extends ConsumerStatefulWidget {
  const TripShoppingTab({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripShoppingTab> createState() => _TripShoppingTabState();
}

class _TripShoppingTabState extends ConsumerState<TripShoppingTab>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'shoppingItems';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripShoppingStoreProvider).currentUid;

  Future<void> _edit([TripShoppingItem? initial]) async {
    final store = ref.read(tripShoppingStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripShoppingEditor(
        tripId: widget.tripId,
        authorUid: uid,
        memberNames: ref.read(tripStaysMemberNamesProvider(widget.tripId)),
        defaultCurrency:
            ref.read(tripStaysTripInfoProvider(widget.tripId))?.currency ??
            'EUR',
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
    final store = ref.watch(tripShoppingStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;

    return TripSectionScaffold<TripShoppingItem>(
      tripId: tripId,
      keyPrefix: 'shopping',
      title: l10n.tripShoppingTitle,
      addLabel: l10n.shoppingAdd,
      onAdd: _edit,
      items: ref.watch(tripShoppingProvider(tripId)),
      emptyIcon: Icons.shopping_bag_rounded,
      emptyText: l10n.shoppingEmpty,
      body: (items) {
        final shown =
            _filter.apply(
              items,
              today: DateTime.now(),
              dayOf: (_) => null,
              statusOf: (i) => i.bought ? 'done' : 'todo',
              kindOf: (i) => i.forUid ?? '',
            )..sort((a, b) {
              final rank = TripSectionPriority.rank(
                a.priority,
              ).compareTo(TripSectionPriority.rank(b.priority));
              return rank != 0
                  ? rank
                  : a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'shopping',
              onClear: () => setState(() => _filter = _filter.cleared()),
              shown: shown.length,
              total: items.length,
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                statuses: [
                  ('todo', l10n.shoppingToBuy),
                  ('done', l10n.shoppingBought),
                ],
                kinds: [for (final e in names.entries) (e.key, e.value)],
                dated: false,
                kindTitle: l10n.shoppingFor,
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripShoppingItem>(
                keyPrefix: 'shopping',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (i) => tripShoppingEntry(context, i, nameOf),
                extraOf: (i) => TripSectionDoneBox(
                  key: Key('shopping-done-${i.id}'),
                  label: l10n.shoppingBought,
                  value: i.bought,
                  onChanged: () => store
                      .update(i.toggled(uid))
                      .catchError((Object _) => _saveFailed()),
                ),
                onEdit: _edit,
                canDelete: (i) =>
                    uid != null && (uid == i.createdByUid || uid == ownerUid),
                onDelete: (i) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'shopping',
                  name: i.name,
                  delete: () => store.delete(i),
                ),
                api: ref.watch(tripStaysBudgetApiProvider(tripId)),
                expenseOf: (i) {
                  final real = i.actualCostMinorUnits != null;
                  return TripSectionExpenseTarget(
                    keyPrefix: 'shopping',
                    id: i.id,
                    title: i.name,
                    category: 'shopping',
                    minorUnits: real
                        ? i.actualCostMinorUnits
                        : i.estimatedCostMinorUnits,
                    currency: real
                        ? i.actualCostCurrency
                        : i.estimatedCostCurrency,
                    expenseId: i.expenseId,
                    link: (expenseId) => store.linkExpense(i, expenseId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
