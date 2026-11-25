// Elenco degli elementi di una sezione (già filtrati e ordinati), centrato e
// largo al massimo 820 punti, con eventuali avvisi in cima e titoli di
// gruppo facoltativi (es. zona o giorno). Ogni elemento appare come card,
// card compatta o riga secondo la vista scelta; le card si costruiscono
// solo quando stanno per apparire. L'elemento segnato da "Cerca" viene
// raggiunto e messo in risalto per qualche secondo (tappa 2b).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_section_item.dart';
import '../models/trip_section_view.dart';
import 'trip_section_card.dart';
import 'trip_section_compact.dart';
import 'trip_section_entry.dart';
import 'trip_section_expense_actions.dart';
import 'trip_section_expense_widgets.dart';
import 'trip_section_focus.dart';
import 'trip_section_menu.dart';
import 'trip_section_quick_actions.dart';

part 'trip_section_list_item.dart';

class TripSectionList<T extends TripSectionItem>
    extends ConsumerStatefulWidget {
  const TripSectionList({
    super.key,
    required this.keyPrefix,
    required this.items,
    required this.view,
    required this.entryOf,
    required this.onEdit,
    required this.canDelete,
    required this.onDelete,
    this.statusOf,
    this.expenseOf,
    this.api,
    this.header = const [],
    this.extraOf,
    this.launch,
    this.onOpen,
    this.groupOf,
  });

  final String keyPrefix;
  final List<T> items;
  final TripSectionView view;
  final TripSectionEntry Function(T item) entryOf;
  final void Function(T item) onEdit;
  final bool Function(T item) canDelete;
  final void Function(T item) onDelete;

  /// Colored status for the Dettagli row.
  final (String, Color)? Function(T item)? statusOf;

  /// Expense of the item; null for sections without expenses.
  final TripSectionExpenseTarget Function(T item)? expenseOf;
  final BudgetApi? api;

  /// Notices above the items.
  final List<Widget> header;

  /// Extra content in the big card (e.g. votes), above the expense.
  final Widget? Function(T item)? extraOf;
  final AmaterasuLaunch? launch;

  /// Opens the item when its card or row is tapped (e.g. a checklist).
  final void Function(T item)? onOpen;

  /// Group title of an item (items already sorted by group); a title is
  /// shown above the first item of each group.
  final String Function(T item)? groupOf;

  @override
  ConsumerState<TripSectionList<T>> createState() => _TripSectionListState<T>();
}

class _TripSectionListState<T extends TripSectionItem>
    extends ConsumerState<TripSectionList<T>> {
  final _scroll = ScrollController();
  final _focusKey = GlobalKey();
  String? _lit;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Highlights the item marked by Cerca, or says that a filter hides it.
  Future<void> _reveal(String id) async {
    ref.read(tripSectionFocusProvider.notifier).set(null);
    if (!widget.items.any((item) => item.id == id)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tripSectionFocusHidden)));
      return;
    }
    setState(() => _lit = id);
    await WidgetsBinding.instance.endOfFrame;
    await tripSectionReveal(_scroll, _focusKey);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted && _lit == id) setState(() => _lit = null);
  }

  /// The item, with an accent border while it is highlighted.
  Widget _marked(T item, Widget child) => item.id != _lit
      ? child
      : DecoratedBox(
          key: _focusKey,
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AmaterasuColors.primary, width: 2),
          ),
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(tripSectionFocusProvider);
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(tripSectionFocusProvider) == focus) {
          _reveal(focus);
        }
      });
    }
    final keyPrefix = widget.keyPrefix;
    final items = widget.items;
    final view = widget.view;
    final header = widget.header;
    final onOpen = widget.onOpen;
    final groupOf = widget.groupOf;
    return _list(keyPrefix, items, view, header, onOpen, groupOf);
  }

  Widget _list(
    String keyPrefix,
    List<T> items,
    TripSectionView view,
    List<Widget> header,
    void Function(T item)? onOpen,
    String Function(T item)? groupOf,
  ) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView.separated(
        key: Key('$keyPrefix-list'),
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => SizedBox(
          height: index == 0 ? 0 : (view == TripSectionView.details ? 8 : 12),
        ),
        itemBuilder: (context, index) {
          if (index == 0) return Column(children: header);
          final item = items[index - 1];
          final open = onOpen;
          final child = _marked(
            item,
            open == null
                ? _item(item)
                : GestureDetector(
                    key: Key('$keyPrefix-open-${item.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => open(item),
                    child: _item(item),
                  ),
          );
          final group = groupOf?.call(item);
          if (group == null ||
              (index > 1 && groupOf!(items[index - 2]) == group)) {
            return child;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  group,
                  key: Key('$keyPrefix-group-$group'),
                  style: const TextStyle(
                    color: AmaterasuColors.accentGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              child,
            ],
          );
        },
      ),
    ),
  );
}
