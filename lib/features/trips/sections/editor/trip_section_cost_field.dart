// Costo previsto negli editor delle sezioni: importo e valuta (stesso
// formato degli importi del budget). Diventa il valore di partenza di
// "Crea spesa"; vuoto = nessun costo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Text and currency of an expected cost while editing.
class TripSectionCostDraft {
  TripSectionCostDraft({int? minorUnits, String? currency, String? fallback})
    : currency = currency ?? fallback ?? 'EUR',
      text = TextEditingController(text: _text(minorUnits, currency));

  final TextEditingController text;
  String currency;

  static String _text(int? minor, String? currency) {
    if (minor == null || currency == null) return '';
    try {
      return BudgetMoneyInput.plainText(minor, currency);
    } catch (_) {
      return '';
    }
  }

  /// Minor units; null when empty, -1 when it is not an amount (the
  /// validators then report it).
  int? get minorUnits {
    final value = text.text.trim();
    if (value.isEmpty) return null;
    try {
      return BudgetMoneyInput.parse(value, currency);
    } catch (_) {
      return -1;
    }
  }

  /// Currency to save: only when there is an amount.
  String? get savedCurrency => minorUnits == null ? null : currency;

  void dispose() => text.dispose();
}

class TripSectionCostField extends StatelessWidget {
  const TripSectionCostField({
    super.key,
    required this.keyPrefix,
    required this.draft,
    required this.onChanged,
    this.label,
  });

  final String keyPrefix;
  final TripSectionCostDraft draft;
  final VoidCallback onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final codes = {
      ...CurrencyMinorUnits.supportedCodes,
      draft.currency,
    }.toList()..sort();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: Key('$keyPrefix-cost'),
            controller: draft.text,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: label ?? l10n.sectionsCost,
              helperText: l10n.sectionsCostHint,
              helperMaxLines: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            key: Key('$keyPrefix-cost-currency'),
            initialValue: draft.currency,
            menuMaxHeight: 320,
            decoration: InputDecoration(labelText: l10n.sectionsCostCurrency),
            items: [
              for (final code in codes)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (code) {
              if (code == null) return;
              draft.currency = code;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
