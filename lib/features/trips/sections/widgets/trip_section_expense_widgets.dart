// Spesa di un elemento nelle viste: in fondo alla card titolo e importo con
// "Vedi spesa" oppure "Crea spesa" / "Collega spesa esistente"; come icona
// (Elenco e Dettagli) un menu o "Vedi spesa". Come negli alloggi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_shown_amount_text.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_expense_actions.dart';
import 'trip_section_quick_button.dart';

void _view(
  BuildContext context,
  BudgetApi api,
  String id,
  Map<String, dynamic> data,
) => showDialog<void>(
  context: context,
  builder: (_) => BudgetExpenseDetailsDialog(
    expense: data,
    expenseId: id,
    api: api,
    isPrivate: false,
  ),
);

/// Linked expense document, looked up in the shared expenses.
Widget _withExpense(
  BudgetApi api,
  String expenseId,
  Widget Function(BuildContext, Map<String, dynamic>?, bool loaded) builder,
) => StreamBuilder(
  stream: api.sharedExpenses(),
  builder: (context, snapshot) {
    final docs = snapshot.data?.docs ?? const [];
    final matches = docs.where((doc) => doc.id == expenseId);
    return builder(
      context,
      matches.isEmpty ? null : matches.first.data(),
      snapshot.hasData,
    );
  },
);

class TripSectionExpenseFooter extends StatelessWidget {
  const TripSectionExpenseFooter({
    super.key,
    required this.target,
    required this.api,
  });

  final TripSectionExpenseTarget target;
  final BudgetApi api;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = target.keyPrefix;
    final id = target.id;
    const accent = TextStyle(color: AmaterasuColors.accentBudget);
    final expenseId = target.expenseId;
    if (expenseId == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              key: Key('$p-expense-create-$id'),
              onPressed: () => createTripSectionExpense(context, api, target),
              icon: const Icon(Icons.add_card_outlined, size: 18),
              label: Text(l10n.sectionsExpenseCreate, style: accent),
            ),
            TextButton(
              key: Key('$p-expense-link-$id'),
              onPressed: () =>
                  linkExistingTripSectionExpense(context, api, target),
              child: Text(
                l10n.sectionsExpenseLinkExisting,
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return _withExpense(api, expenseId, (context, data, loaded) {
      if (data == null) {
        if (!loaded) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            l10n.sectionsExpenseNotVisible,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 13,
            ),
          ),
        );
      }
      final amount = tripSectionExpenseAmount(data);
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: AmaterasuColors.accentBudget,
            ),
            _ExpenseLine(
              title: l10n.sectionsExpenseLinkedTitle(
                data['title']?.toString() ?? '',
              ),
              expense: data,
              amount: amount,
            ),
            TextButton(
              key: Key('$p-expense-view-$id'),
              onPressed: () => _view(context, api, expenseId, data),
              child: Text(l10n.sectionsExpenseView, style: accent),
            ),
          ],
        ),
      );
    });
  }
}

class TripSectionExpenseButton extends StatelessWidget {
  const TripSectionExpenseButton({
    super.key,
    required this.target,
    required this.api,
  });

  final TripSectionExpenseTarget target;
  final BudgetApi api;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final key = Key('${target.keyPrefix}-quick-expense-${target.id}');
    final expenseId = target.expenseId;
    if (expenseId == null) {
      return PopupMenuButton<bool>(
        key: key,
        tooltip: l10n.sectionsExpense,
        padding: EdgeInsets.zero,
        iconSize: TripSectionQuickButton.iconSize,
        icon: const Icon(
          Icons.add_card_outlined,
          color: AmaterasuColors.accentBudget,
        ),
        color: AmaterasuColors.surfaceCard,
        onSelected: (create) => create
            ? createTripSectionExpense(context, api, target)
            : linkExistingTripSectionExpense(context, api, target),
        itemBuilder: (_) => [
          PopupMenuItem(value: true, child: Text(l10n.sectionsExpenseCreate)),
          PopupMenuItem(
            value: false,
            child: Text(l10n.sectionsExpenseLinkExisting),
          ),
        ],
      );
    }
    return _withExpense(
      api,
      expenseId,
      (context, data, loaded) => TripSectionQuickButton(
        key: key,
        icon: Icons.receipt_long_outlined,
        tooltip: data == null && loaded
            ? l10n.sectionsExpenseNotVisible
            : l10n.sectionsExpenseView,
        onPressed: data == null
            ? null
            : () => _view(context, api, expenseId, data),
      ),
    );
  }
}

/// "Spesa collegata: title · amount", the amount in the display currency
/// with the rate of the expense (same as the budget, Extra E7).
class _ExpenseLine extends StatelessWidget {
  const _ExpenseLine({
    required this.title,
    required this.expense,
    required this.amount,
  });

  final String title;
  final Map<String, dynamic> expense;

  /// Original amount text ('' when unknown).
  final String amount;

  static const _style = TextStyle(
    color: AmaterasuColors.textPrimary,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    final snapshot = expense['snapshot'];
    final total = snapshot is Map ? snapshot['total'] : null;
    final minor = total is Map ? total['minorUnits'] : null;
    final currency = total is Map ? total['currency'] : null;
    if (minor is! int || currency is! String) {
      return Text(amount.isEmpty ? title : '$title · $amount', style: _style);
    }
    return BudgetShownAmountText(
      minorUnits: minor,
      currency: currency,
      expense: expense,
      text: (a) => '$title · $a',
      style: _style,
    );
  }
}
