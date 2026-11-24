// Elenco degli elementi di una sezione (già filtrati e ordinati), centrato e
// largo al massimo 820 punti, con eventuali avvisi in cima. Ogni elemento
// appare come card, card compatta o riga secondo la vista scelta; le card
// si costruiscono solo quando stanno per apparire.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import '../models/trip_section_item.dart';
import '../models/trip_section_view.dart';
import 'trip_section_card.dart';
import 'trip_section_compact.dart';
import 'trip_section_entry.dart';
import 'trip_section_expense_actions.dart';
import 'trip_section_expense_widgets.dart';
import 'trip_section_menu.dart';
import 'trip_section_quick_actions.dart';

class TripSectionList<T extends TripSectionItem> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView.separated(
        key: Key('$keyPrefix-list'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => SizedBox(
          height: index == 0 ? 0 : (view == TripSectionView.details ? 8 : 12),
        ),
        itemBuilder: (context, index) {
          if (index == 0) return Column(children: header);
          return _item(items[index - 1]);
        },
      ),
    ),
  );

  Widget _item(T item) {
    final entry = entryOf(item);
    final target = expenseOf?.call(item);
    final api = this.api;
    final remove = canDelete(item) ? () => onDelete(item) : null;
    final compact = view != TripSectionView.cards;
    final actions = TripSectionQuickActions(
      keyPrefix: keyPrefix,
      entry: entry,
      expense: compact && target != null && api != null
          ? TripSectionExpenseButton(target: target, api: api)
          : null,
      onEdit: compact ? () => onEdit(item) : null,
      launch: launch,
      menu: TripSectionMenu(
        keyPrefix: keyPrefix,
        id: item.id,
        onDelete: remove,
        dense: compact,
      ),
    );
    return switch (view) {
      TripSectionView.list => TripSectionCompactCard(
        keyPrefix: keyPrefix,
        entry: entry,
        actions: actions,
      ),
      TripSectionView.details => TripSectionDetailsRow(
        keyPrefix: keyPrefix,
        entry: entry,
        actions: actions,
        status: statusOf?.call(item),
      ),
      TripSectionView.cards => TripSectionCard(
        keyPrefix: keyPrefix,
        entry: entry,
        actions: actions,
        launch: launch,
        onEdit: () => onEdit(item),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?extraOf?.call(item),
            if (target != null && api != null)
              TripSectionExpenseFooter(target: target, api: api),
          ],
        ),
      ),
    };
  }
}
