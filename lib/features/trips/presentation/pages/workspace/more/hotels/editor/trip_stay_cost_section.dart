// Sezione "Costo e cancellazione" dell'editor: costo previsto facoltativo
// (importo e valuta, diventa il valore di partenza di "Crea spesa") e
// ultimo giorno di cancellazione gratuita, anch'esso facoltativo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_currency_choice.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayCostSection extends StatelessWidget {
  const TripStayCostSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  Future<void> _pickCancellation(BuildContext context) async {
    final current = draft.freeCancellationUntil ?? draft.checkInDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    draft.freeCancellationUntil = picked;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = MaterialLocalizations.of(context).formatMediumDate;
    final until = draft.freeCancellationUntil;
    return TripStayEditorSection(
      title: l10n.staysSectionCost,
      icon: Icons.payments_outlined,
      children: [
        BudgetCurrencyButton(
          key: const Key('stay-cost-currency'),
          currency: draft.costCurrency,
          label: l10n.staysCostCurrency,
          onPressed: () async {
            final code = await pickBudgetCurrency(
              context,
              selected: draft.costCurrency,
              title: l10n.staysCostCurrency,
            );
            if (code == null) return;
            draft.costCurrency = code;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('stay-cost'),
          controller: draft.cost,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysCost,
            suffixText: draft.costCurrency,
            helperText: l10n.staysCostHint,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('stay-cancellation-day'),
              onPressed: () => _pickCancellation(context),
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: Text(
                '${l10n.staysFreeCancellation}: '
                '${until == null ? l10n.staysFreeCancellationNone : format(until)}',
              ),
            ),
            if (until != null)
              IconButton(
                key: const Key('stay-cancellation-clear'),
                tooltip: l10n.staysFreeCancellationClear,
                onPressed: () {
                  draft.freeCancellationUntil = null;
                  onChanged();
                },
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AmaterasuColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
