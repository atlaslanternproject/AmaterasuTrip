// Blocco "Valute" di Converti: importo, valuta di partenza e di arrivo con
// il selettore comune del budget e risultato con gli stessi tassi e la
// stessa logica del budget (budgetDisplayQuote, una sola cache), con fonte
// e data del cambio. Non salva nulla.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/budget/data/budget_fx_service.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_currency_choice.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_display_amount.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripConvertCurrencyBlock extends StatefulWidget {
  const TripConvertCurrencyBlock({
    super.key,
    required this.from,
    required this.to,
    this.loader,
  });

  final String from;
  final String to;

  /// Replaces the network rate in tests.
  final BudgetQuoteLoader? loader;

  @override
  State<TripConvertCurrencyBlock> createState() =>
      _TripConvertCurrencyBlockState();
}

class _TripConvertCurrencyBlockState extends State<TripConvertCurrencyBlock> {
  late String _from = widget.from;
  late String _to = widget.to;
  final _amount = TextEditingController(text: '100');
  Future<BudgetFxQuote?>? _quote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _load() => _quote = _from == _to
      ? null
      : budgetDisplayQuote(from: _from, to: _to, loader: widget.loader);

  Future<void> _pick(bool from) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await pickBudgetCurrency(
      context,
      selected: from ? _from : _to,
      title: from ? l10n.convertFrom : l10n.convertTo,
    );
    if (code == null) return;
    setState(() {
      from ? _from = code : _to = code;
      _load();
    });
  }

  String? _result(BudgetFxQuote? quote) {
    try {
      final minor = BudgetMoneyInput.parse(_amount.text, _from);
      if (_from == _to) return BudgetMoneyFormatter.format(minor, _to);
      final converted = BudgetFxService.convertMinor(minor, _from, _to, quote);
      return converted == null
          ? null
          : BudgetMoneyFormatter.format(converted, _to);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionBlock(
      title: l10n.convertCurrencies,
      icon: Icons.currency_exchange_rounded,
      children: [
        TextField(
          key: const Key('convert-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.convertAmount),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BudgetCurrencyButton(
              key: const Key('convert-from'),
              currency: _from,
              label: l10n.convertFrom,
              onPressed: () => _pick(true),
            ),
            IconButton(
              key: const Key('convert-swap'),
              tooltip: l10n.convertSwap,
              onPressed: () => setState(() {
                final swapped = _from;
                _from = _to;
                _to = swapped;
                _load();
              }),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            BudgetCurrencyButton(
              key: const Key('convert-to'),
              currency: _to,
              label: l10n.convertTo,
              onPressed: () => _pick(false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder(
          future: _quote,
          builder: (context, snap) {
            final waiting =
                _quote != null && snap.connectionState != ConnectionState.done;
            final result = waiting ? null : _result(snap.data);
            final quote = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waiting ? '…' : (result ?? l10n.convertUnavailable),
                  key: const Key('convert-result'),
                  style: const TextStyle(
                    color: AmaterasuColors.accentGold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (quote != null)
                  Text(
                    l10n.convertRateSource(quote.source, quote.observedIso),
                    style: const TextStyle(
                      color: AmaterasuColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
