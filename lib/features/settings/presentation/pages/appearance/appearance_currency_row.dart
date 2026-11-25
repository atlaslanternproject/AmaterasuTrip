// Riga di una valuta della pagina "Aspetto": il pulsante valuta comune del
// budget ("Etichetta: EUR") che apre lo stesso pannello di scelta, e una
// × per tornare al valore automatico (valuta del viaggio o originale).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_currency_choice.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AppearanceCurrencyRow extends StatelessWidget {
  const AppearanceCurrencyRow({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.value,
    required this.emptyText,
    required this.onChanged,
  });

  final String keyPrefix;
  final String label;
  final String? value;

  /// Shown when nothing is chosen (automatic value).
  final String emptyText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = value;
    return Row(
      children: [
        Flexible(
          child: BudgetCurrencyButton(
            key: Key(keyPrefix),
            currency: current ?? emptyText,
            label: label,
            onPressed: () async {
              final code = await pickBudgetCurrency(
                context,
                selected: current,
                title: label,
              );
              if (code != null) onChanged(code);
            },
          ),
        ),
        if (current != null)
          IconButton(
            key: Key('$keyPrefix-clear'),
            tooltip: l10n.appearanceCurrencyAuto,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}
