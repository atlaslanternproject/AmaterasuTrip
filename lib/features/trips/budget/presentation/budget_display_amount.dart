// Mostra un importo nella valuta scelta per la visualizzazione,
// senza mai modificare la spesa originale. La scelta del tasso (tasso
// bloccato della spesa, poi storico del giorno, poi ultimo) è anche una
// funzione pubblica, usata uguale fuori dal budget (Extra E7).

import 'budget_expense_day.dart';
import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../data/budget_fx_service.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

typedef BudgetQuoteLoader =
    Future<BudgetFxQuote> Function(String from, String to);

/// One exchange service (and cache) for every displayed amount.
final BudgetFxService budgetDisplayFx = BudgetFxService();

/// Rate used to show [from] amounts in [to]: the rate locked in [expense],
/// else the historical rate of its day, else (no expense) the latest one.
/// Null when no rate is available. Never changes any amount.
Future<BudgetFxQuote?> budgetDisplayQuote({
  required String from,
  required String to,
  Map<String, dynamic>? expense,
  BudgetQuoteLoader? loader,
}) async {
  try {
    if (expense != null) {
      final locked = BudgetFxQuote.fromLocked(expense['fxHistorical']);
      if (locked?.base == from && locked?.quote == to) {
        return locked;
      }
      final day = budgetExpenseDay(expense);
      if (day == null) return null;
      return await budgetDisplayFx.historical(from, to, day);
    }
    return await (loader ?? budgetDisplayFx.latest)(from, to);
  } catch (_) {
    return null;
  }
}

/// Display-only amount. The original expense is never modified.
class BudgetDisplayAmount extends StatefulWidget {
  const BudgetDisplayAmount({
    super.key,
    required this.minorUnits,
    required this.originalCurrency,
    required this.displayCurrency,
    this.fontSize = 17,
    this.quoteLoader,
    this.expense,
  });

  final int minorUnits;
  final String originalCurrency;
  final String displayCurrency;
  final double fontSize;
  final Map<String, dynamic>? expense;
  final BudgetQuoteLoader? quoteLoader;

  @override
  State<BudgetDisplayAmount> createState() => _BudgetDisplayAmountState();
}

class _BudgetDisplayAmountState extends State<BudgetDisplayAmount> {
  Future<BudgetFxQuote?>? _quoteFuture;

  @override
  void initState() {
    super.initState();
    _prepareQuote();
  }

  @override
  void didUpdateWidget(covariant BudgetDisplayAmount oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.originalCurrency != widget.originalCurrency ||
        oldWidget.displayCurrency != widget.displayCurrency ||
        oldWidget.expense != widget.expense ||
        oldWidget.quoteLoader != widget.quoteLoader) {
      _prepareQuote();
    }
  }

  void _prepareQuote() {
    if (widget.originalCurrency == widget.displayCurrency) {
      _quoteFuture = null;
    } else {
      _quoteFuture = _loadQuote();
    }
  }

  Future<BudgetFxQuote?> _loadQuote() => budgetDisplayQuote(
    from: widget.originalCurrency,
    to: widget.displayCurrency,
    expense: widget.expense,
    loader: widget.quoteLoader,
  );

  // TODO(audit): C8 _money ripetuto in 3 file con gestione errori diversa: decidere una sola regola.
  String _money(int minor, String currency) {
    try {
      return BudgetMoneyFormatter.format(minor, currency);
    } catch (_) {
      return '$minor $currency';
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    final original = _money(widget.minorUnits, widget.originalCurrency);

    Widget content({
      required String prominent,
      String? warning,
      String? source,
      bool showOriginal = true,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prominent,
            style: TextStyle(
              color: AmaterasuColors.accentGold,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (showOriginal) const SizedBox(height: 3),
          if (showOriginal)
            Text(
              '${budgetL10n(it).btAmountOriginal}: $original',
              style: const TextStyle(
                color: AmaterasuColors.textSecondary,
                fontSize: 11,
              ),
            ),
          if (warning != null)
            Text(
              warning,
              style: const TextStyle(
                color: AmaterasuColors.accentGold,
                fontSize: 11,
              ),
            ),
          if (source != null)
            Tooltip(
              message: source,
              child: Text(
                budgetL10n(it).btAmountAutomaticExchangeRate,
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      );
    }

    // Same currency: only the amount (Extra E7), no "Original" line.
    if (widget.originalCurrency == widget.displayCurrency) {
      return content(prominent: original, showOriginal: false);
    }

    return FutureBuilder<BudgetFxQuote?>(
      future: _quoteFuture,
      builder: (context, result) {
        if (result.connectionState != ConnectionState.done) {
          return content(
            prominent: '— ${widget.displayCurrency}',
            warning: budgetL10n(it).btAmountConverting,
          );
        }

        final quote = result.data;
        int? converted;

        try {
          converted = BudgetFxService.convertMinor(
            widget.minorUnits,
            widget.originalCurrency,
            widget.displayCurrency,
            quote,
          );
        } catch (_) {
          converted = null;
        }

        if (converted == null) {
          return content(
            prominent: '— ${widget.displayCurrency}',
            warning: budgetL10n(it).btAmountExchangeRateUnavailable,
          );
        }

        return content(
          prominent: _money(converted, widget.displayCurrency),
          source: quote == null
              ? null
              : '${quote.source} · ${quote.observedIso}',
        );
      },
    );
  }
}
