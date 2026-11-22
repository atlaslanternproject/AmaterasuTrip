// Parte bassa della card di un soggiorno dedicata alla spesa: titolo e
// importo della spesa collegata con "Vedi spesa", oppure "Crea spesa" e
// "Collega spesa esistente" se non ce n'è una.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_repository.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_expense_actions.dart';

class TripStayExpenseFooter extends StatelessWidget {
  const TripStayExpenseFooter({
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
    const accent = TextStyle(color: AmaterasuColors.accentBudget);

    if (expenseId == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              key: Key('stay-expense-create-${stay.id}'),
              onPressed: () =>
                  createExpenseForStay(context, api, repository, stay),
              icon: const Icon(Icons.add_card_outlined, size: 18),
              label: Text(l10n.staysExpenseCreate, style: accent),
            ),
            TextButton(
              key: Key('stay-expense-link-${stay.id}'),
              onPressed: () =>
                  linkExistingExpenseToStay(context, api, repository, stay),
              child: Text(
                l10n.staysExpenseLinkExisting,
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder(
      stream: api.sharedExpenses(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final matches = docs.where((doc) => doc.id == expenseId);
        final doc = matches.isEmpty ? null : matches.first;
        if (snapshot.hasData && doc == null) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.staysExpenseNotVisible,
              style: const TextStyle(
                color: AmaterasuColors.textMuted,
                fontSize: 13,
              ),
            ),
          );
        }
        if (doc == null) return const SizedBox.shrink();
        final data = doc.data();
        final amount = tripStayExpenseAmount(data);
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
              Text(
                '${l10n.staysExpenseLinkedTitle(data['title']?.toString() ?? '')}'
                '${amount.isEmpty ? '' : ' · $amount'}',
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              TextButton(
                key: Key('stay-expense-view-${stay.id}'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BudgetExpenseDetailsDialog(
                    expense: data,
                    expenseId: expenseId,
                    api: api,
                    isPrivate: false,
                  ),
                ),
                child: Text(l10n.staysExpenseView, style: accent),
              ),
            ],
          ),
        );
      },
    );
  }
}
