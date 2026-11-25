// Spesa collegata a un elemento di una sezione, come negli alloggi: "Crea
// spesa" apre il dialogo spese già compilato (solo condivisa, categoria,
// data, costo previsto) e poi la collega; "Collega spesa esistente" sceglie
// tra le spese condivise.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/widgets/trip_stay_expense_actions.dart'
    show tripStayExpenseAmount;
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// What the expense of an item starts from, and how to link it.
class TripSectionExpenseTarget {
  const TripSectionExpenseTarget({
    required this.keyPrefix,
    required this.id,
    required this.title,
    required this.category,
    required this.link,
    this.expenseId,
    this.date,
    this.minorUnits,
    this.currency,
  });

  final String keyPrefix;
  final String id;

  /// Firestore collection of the item, saved in the expense to go back.
  String get section => switch (keyPrefix) {
    'transport' => 'transports',
    'reservation' => 'reservations',
    'restaurant' => 'restaurants',
    _ => 'shoppingItems',
  };
  final String title;

  /// Budget category, e.g. 'transport', 'food', 'activities'.
  final String category;
  final String? expenseId;
  final DateTime? date;
  final int? minorUnits;
  final String? currency;
  final Future<void> Function(String expenseId) link;
}

/// Total of an expense document, formatted in its currency.
String tripSectionExpenseAmount(Map<String, dynamic> expense) =>
    tripStayExpenseAmount(expense);

Future<void> _link(
  BuildContext context,
  TripSectionExpenseTarget target,
  String expenseId, {
  required bool justCreated,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await target.link(expenseId);
    messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsExpenseLinked)));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          justCreated ? l10n.sectionsExpenseLinkError : l10n.sectionsSaveError,
        ),
      ),
    );
  }
}

Future<void> createTripSectionExpense(
  BuildContext context,
  BudgetApi api,
  TripSectionExpenseTarget target,
) async {
  final hasCost = target.minorUnits != null && target.currency != null;
  final currency = hasCost ? target.currency! : await api.tripCurrency();
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
        initialTitle: target.title,
        initialCategory: target.category,
        initialDate: target.date,
        initialMinorUnits: hasCost ? target.minorUnits : null,
        sharedOnly: true,
        source: (target.section, target.id),
        onCreated: (id) => createdId = id,
      ),
    ),
  );
  final id = createdId;
  if (id == null || !context.mounted) return;
  await _link(context, target, id, justCreated: true);
}

Future<void> linkExistingTripSectionExpense(
  BuildContext context,
  BudgetApi api,
  TripSectionExpenseTarget target,
) async {
  final l10n = AppLocalizations.of(context)!;
  final chosen = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.sectionsExpensePickTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: SizedBox(
        width: 440,
        child: StreamBuilder(
          stream: api.sharedExpenses(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(l10n.sectionsExpenseLoadError);
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final docs = snapshot.data!.docs
                .where((doc) => doc.data()['lifecycle'] != 'cancelled')
                .toList();
            if (docs.isEmpty) return Text(l10n.sectionsExpensePickEmpty);
            return ListView(
              shrinkWrap: true,
              children: [
                for (final doc in docs)
                  ListTile(
                    key: Key('${target.keyPrefix}-pick-${doc.id}'),
                    title: Text(doc.data()['title']?.toString() ?? ''),
                    subtitle: Text(tripSectionExpenseAmount(doc.data())),
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
          child: Text(l10n.sectionsCancel),
        ),
      ],
    ),
  );
  if (chosen == null || !context.mounted) return;
  await _link(context, target, chosen, justCreated: false);
}
