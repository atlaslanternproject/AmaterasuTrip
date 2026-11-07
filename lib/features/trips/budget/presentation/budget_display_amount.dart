import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../data/budget_fx_service.dart';

typedef BudgetQuoteLoader =
    Future<BudgetFxQuote> Function(String from, String to);

/// Display-only amount. The original expense is never modified.
class BudgetDisplayAmount extends StatefulWidget {
  const BudgetDisplayAmount({
    super.key,
    required this.minorUnits,
    required this.originalCurrency,
    required this.displayCurrency,
    this.fontSize = 17,
    this.quoteLoader,
  });

  final int minorUnits;
  final String originalCurrency;
  final String displayCurrency;
  final double fontSize;
  final BudgetQuoteLoader? quoteLoader;

  @override
  State<BudgetDisplayAmount> createState() => _BudgetDisplayAmountState();
}

class _BudgetDisplayAmountState extends State<BudgetDisplayAmount> {
  static final BudgetFxService _fx = BudgetFxService();

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

  Future<BudgetFxQuote?> _loadQuote() async {
    try {
      final loader = widget.quoteLoader ?? _fx.latest;

      return await loader(widget.originalCurrency, widget.displayCurrency);
    } catch (_) {
      return null;
    }
  }

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
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prominent,
            style: TextStyle(
              color: const Color(0xFFE3A66C),
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${it ? "Originale" : "Original"}: $original',
            style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 11),
          ),
          if (warning != null)
            Text(
              warning,
              style: const TextStyle(color: Color(0xFFE3A66C), fontSize: 11),
            ),
          if (source != null)
            Tooltip(
              message: source,
              child: Text(
                it ? 'Cambio automatico' : 'Automatic exchange rate',
                style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 10),
              ),
            ),
        ],
      );
    }

    if (widget.originalCurrency == widget.displayCurrency) {
      return content(prominent: original);
    }

    return FutureBuilder<BudgetFxQuote?>(
      future: _quoteFuture,
      builder: (context, result) {
        if (result.connectionState != ConnectionState.done) {
          return content(
            prominent: '— ${widget.displayCurrency}',
            warning: it ? 'Conversione in corso' : 'Converting',
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
            warning: it
                ? 'Tasso di cambio non disponibile'
                : 'Exchange rate unavailable',
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
