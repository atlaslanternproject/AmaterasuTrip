// Filtro "Spese" dell'Audit Trail: lo Storico del budget del viaggio,
// caricato solo quando si sceglie il filtro, con lo stesso elenco e la
// stessa funzione del server di prima (BudgetHistoryList, non cambiato):
// ognuno vede solo le spese a cui partecipa, le private solo l'autore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_history_view.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Collection code of the "Spese" choice (not a register collection).
const tripAuditExpenses = 'expenses';

class TripAuditExpenses extends ConsumerWidget {
  const TripAuditExpenses({
    super.key,
    required this.tripId,
    required this.otherFilters,
  });

  final String tripId;

  /// Person, action or period are set: they do not apply here.
  final bool otherFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    const muted = TextStyle(color: AmaterasuColors.textSecondary, fontSize: 13);
    return Column(
      key: const Key('audit-expenses'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.b86HistoryVisibility, style: muted),
        if (otherFilters)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.auditExpensesFiltersNote,
              key: const Key('audit-expenses-filters'),
              style: muted,
            ),
          ),
        const SizedBox(height: 8),
        BudgetHistoryList(api: ref.read(tripStaysBudgetApiProvider(tripId))),
      ],
    );
  }
}
