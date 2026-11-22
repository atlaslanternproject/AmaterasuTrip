// Spesa di un soggiorno come icona (viste Elenco e Dettagli): senza spesa
// apre un menu "Crea spesa" / "Collega spesa esistente"; con la spesa
// collegata apre "Vedi spesa". Usa le stesse azioni del piè di card.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_repository.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_expense_actions.dart';
import 'trip_stay_quick_actions.dart';

enum _ExpenseChoice { create, link }

class TripStayExpenseButton extends StatelessWidget {
  const TripStayExpenseButton({
    super.key,
    required this.stay,
    required this.api,
    required this.repository,
  });

  final TripStay stay;
  final BudgetApi api;
  final TripStaysRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expenseId = stay.expenseId;
    if (expenseId == null) {
      return PopupMenuButton<_ExpenseChoice>(
        key: Key('stay-quick-expense-${stay.id}'),
        tooltip: l10n.staysExpense,
        padding: EdgeInsets.zero,
        iconSize: TripStayQuickActions.iconSize,
        icon: const Icon(
          Icons.add_card_outlined,
          color: AmaterasuColors.accentBudget,
        ),
        color: AmaterasuColors.surfaceCard,
        onSelected: (choice) => choice == _ExpenseChoice.create
            ? createExpenseForStay(context, api, repository, stay)
            : linkExistingExpenseToStay(context, api, repository, stay),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _ExpenseChoice.create,
            child: Text(l10n.staysExpenseCreate),
          ),
          PopupMenuItem(
            value: _ExpenseChoice.link,
            child: Text(l10n.staysExpenseLinkExisting),
          ),
        ],
      );
    }

    return StreamBuilder(
      stream: api.sharedExpenses(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final matches = docs.where((doc) => doc.id == expenseId);
        final doc = matches.isEmpty ? null : matches.first;
        return TripStayQuickButton(
          key: Key('stay-quick-expense-${stay.id}'),
          icon: Icons.receipt_long_outlined,
          tooltip: doc == null && snapshot.hasData
              ? l10n.staysExpenseNotVisible
              : l10n.staysExpenseView,
          onPressed: doc == null
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (_) => BudgetExpenseDetailsDialog(
                    expense: doc.data(),
                    expenseId: expenseId,
                    api: api,
                    isPrivate: false,
                  ),
                ),
        );
      },
    );
  }
}
