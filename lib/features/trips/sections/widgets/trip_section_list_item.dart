// Parte di TripSectionList: la singola voce come card, card compatta o
// riga secondo la vista scelta, con azioni rapide, menu ed eventuale
// spesa collegata. Spostata senza cambiamenti dal file principale.

part of 'trip_section_list.dart';

extension _TripSectionListItem<T extends TripSectionItem>
    on _TripSectionListState<T> {
  Widget _item(T item) {
    final w = widget;
    final keyPrefix = w.keyPrefix;
    final view = w.view;
    final launch = w.launch;
    final onEdit = w.onEdit;
    final extraOf = w.extraOf;
    final statusOf = w.statusOf;
    final entry = w.entryOf(item);
    final target = w.expenseOf?.call(item);
    final api = w.api;
    final remove = w.canDelete(item) ? () => w.onDelete(item) : null;
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
