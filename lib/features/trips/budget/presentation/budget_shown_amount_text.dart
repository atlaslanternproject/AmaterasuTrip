// Importo in una riga di testo nella valuta di visualizzazione di
// Impostazioni > Aspetto (Extra E7), per sezioni e alloggi: stesso tasso e
// stessa logica del budget (budgetDisplayQuote, una sola cache), con
// "Originale: X" solo quando la valuta è diversa. Nessun importo cambia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../calculations/budget_money_formatter.dart';
import '../data/budget_fx_service.dart';
import 'budget_display_amount.dart';

class BudgetShownAmountText extends ConsumerStatefulWidget {
  const BudgetShownAmountText({
    super.key,
    required this.minorUnits,
    required this.currency,
    required this.text,
    this.expense,
    this.style,
  });

  final int minorUnits;
  final String currency;

  /// Whole line for a formatted amount, e.g. "Costo previsto: € 12,00".
  final String Function(String amount) text;

  /// Expense document, to use its locked or historical rate as the budget.
  final Map<String, dynamic>? expense;
  final TextStyle? style;

  @override
  ConsumerState<BudgetShownAmountText> createState() =>
      _BudgetShownAmountTextState();
}

class _BudgetShownAmountTextState extends ConsumerState<BudgetShownAmountText> {
  Future<BudgetFxQuote?>? _quote;
  String? _quoteFor;

  String _money(int minor, String currency) {
    try {
      return BudgetMoneyFormatter.format(minor, currency);
    } catch (_) {
      return '$minor $currency';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final original = _money(widget.minorUnits, widget.currency);
    final shown = ref.watch(
      amaterasuAppearanceProvider.select((a) => a.shownCurrency),
    );
    if (shown == null || shown == widget.currency) {
      return Text(widget.text(original), style: widget.style);
    }
    final key = '${widget.currency}>$shown';
    if (_quoteFor != key) {
      _quoteFor = key;
      _quote = budgetDisplayQuote(
        from: widget.currency,
        to: shown,
        expense: widget.expense,
      );
    }
    return FutureBuilder(
      future: _quote,
      builder: (context, snap) {
        int? converted;
        try {
          converted = BudgetFxService.convertMinor(
            widget.minorUnits,
            widget.currency,
            shown,
            snap.data,
          );
        } catch (_) {
          converted = null;
        }
        if (converted == null) {
          return Text(widget.text(original), style: widget.style);
        }
        return Text(
          '${widget.text(_money(converted, shown))} · '
          '${l10n.btAmountOriginal}: $original',
          style: widget.style,
        );
      },
    );
  }
}
