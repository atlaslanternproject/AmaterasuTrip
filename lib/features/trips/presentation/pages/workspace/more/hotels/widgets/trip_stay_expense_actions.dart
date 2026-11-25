// Spesa di un soggiorno: "Crea spesa" apre il dialogo spese già compilato
// (solo spesa condivisa, categoria Alloggio, data di check-in, importo e
// valuta del costo previsto se c'è) e poi la
// collega; "Collega spesa esistente" sceglie tra le spese condivise.

import 'package:amaterasutrip/core/appearance/amaterasu_entry_currency.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_repository.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> _link(
  BuildContext context,
  TripStaysRepository repository,
  TripStay stay,
  String expenseId, {
  required bool justCreated,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repository.linkExpense(
      tripId: stay.tripId,
      stayId: stay.id,
      expenseId: expenseId,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.staysExpenseLinked)));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          justCreated ? l10n.staysExpenseLinkError : l10n.staysSaveError,
        ),
      ),
    );
  }
}

Future<void> createExpenseForStay(
  BuildContext context,
  BudgetApi api,
  TripStaysRepository repository,
  TripStay stay,
) async {
  final cost = stay.estimatedCostMinorUnits;
  final costCurrency = stay.estimatedCostCurrency;
  final hasCost = cost != null && costCurrency != null;
  // With a cost its currency stays; otherwise Appearance, then the trip.
  final preferred = amaterasuDefaultEntryCurrency(context);
  final currency = hasCost
      ? costCurrency
      : (preferred ?? await api.tripCurrency());
  if (!context.mounted) return;
  String? createdId;
  await showDialog<bool>(
    context: context,
    // Same look as on the expenses page.
    builder: (dialogContext) => Theme(
      data: Theme.of(dialogContext).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AmaterasuColors.accentBudget,
          brightness: Brightness.dark,
        ),
      ),
      child: BudgetCreateDialog(
        api: api,
        currency: currency,
        initialTitle: stay.name,
        initialCategory: 'accommodation',
        initialDate: stay.checkInDate,
        initialMinorUnits: hasCost ? cost : null,
        sharedOnly: true,
        source: ('stays', stay.id),
        onCreated: (id) => createdId = id,
      ),
    ),
  );
  final id = createdId;
  if (id == null || !context.mounted) return;
  await _link(context, repository, stay, id, justCreated: true);
}

Future<void> linkExistingExpenseToStay(
  BuildContext context,
  BudgetApi api,
  TripStaysRepository repository,
  TripStay stay,
) async {
  final l10n = AppLocalizations.of(context)!;
  final chosen = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.staysExpensePickTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: SizedBox(
        width: 440,
        child: StreamBuilder(
          stream: api.sharedExpenses(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(l10n.staysExpenseLoadError);
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs
                .where((doc) => doc.data()['lifecycle'] != 'cancelled')
                .toList();
            if (docs.isEmpty) return Text(l10n.staysExpensePickEmpty);
            return ListView(
              shrinkWrap: true,
              children: [
                for (final doc in docs)
                  ListTile(
                    key: Key('stay-pick-${doc.id}'),
                    title: Text(doc.data()['title']?.toString() ?? ''),
                    subtitle: Text(_amount(doc.data())),
                    onTap: () => Navigator.pop(dialogContext, doc.id),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.staysCancel),
        ),
      ],
    ),
  );
  if (chosen == null || !context.mounted) return;
  await _link(context, repository, stay, chosen, justCreated: false);
}

/// Total of an expense document, formatted in its currency.
String _amount(Map<String, dynamic> expense) {
  final total = expense['snapshot'] is Map
      ? (expense['snapshot'] as Map)['total']
      : null;
  if (total is! Map ||
      total['minorUnits'] is! int ||
      total['currency'] is! String) {
    return '';
  }
  return BudgetMoneyFormatter.format(
    total['minorUnits'] as int,
    total['currency'] as String,
  );
}

String tripStayExpenseAmount(Map<String, dynamic> expense) => _amount(expense);
