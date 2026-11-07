import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
import '../../presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import '../../presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'budget_category_picker.dart';
import 'budget_expense_filters.dart';

class BudgetDisplayChoice {
  const BudgetDisplayChoice({required this.filters, required this.currency});

  final BudgetExpenseFilters filters;
  final String currency;
}

abstract final class BudgetExpensesToolbar {
  static const _surface = Color(0xFF241A16);
  static const _border = Color(0xFF49352A);
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _orange = Color(0xFFE17A43);
  static const _gold = Color(0xFFE3A66C);

  static Future<String?> _pickCurrency(
    BuildContext context,
    String selected,
    bool it,
  ) async {
    final supported = CurrencyMinorUnits.supportedCodes.toSet();
    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: it ? 'it' : 'en',
      );
      currencies = fetched
          .where((item) => supported.contains(item.code.toUpperCase()))
          .toList();
      final present = currencies.map((item) => item.code.toUpperCase()).toSet();
      currencies.addAll(
        supported
            .difference(present)
            .map((code) => TripCurrency(code: code, name: code, symbol: code)),
      );
    } catch (_) {
      currencies = supported
          .map((code) => TripCurrency(code: code, name: code, symbol: code))
          .toList();
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    if (!context.mounted) return null;

    final picked = await showModalBottomSheet<TripCurrency>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF231915),
      builder: (pickerContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: selected,
          title: it ? 'Valuta di visualizzazione' : 'Display currency',
          searchHint: it ? 'Cerca una valuta' : 'Search currencies',
          noResultsText: it ? 'Nessuna valuta trovata' : 'No currencies found',
        ),
      ),
    );

    return picked?.code.toUpperCase();
  }

  static Future<BudgetDisplayChoice?> chooseFilters(
    BuildContext context, {
    required BudgetExpenseFilters filters,
    required Map<String, String> categoryNames,
    required String displayCurrency,
    required String tripCurrency,
  }) async {
    final it = Localizations.localeOf(context).languageCode == 'it';

    var draft = filters;
    var currency = displayCurrency;

    final categories = <String, String>{
      '': it ? 'Tutte le categorie' : 'All categories',
      for (final code in const [
        'accommodation',
        'food',
        'transport',
        'activities',
        'shopping',
        'other',
      ])
        code: BudgetCategoryPicker.label(code, it),
      ...categoryNames,
    };

    return showModalBottomSheet<BudgetDisplayChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it ? 'Filtri e visualizzazione' : 'Filters and display',
                      style: const TextStyle(
                        color: _cream,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      it
                          ? 'Personalizza come consulti le spese.'
                          : 'Customize how you view expenses.',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      it ? 'Valuta di visualizzazione' : 'Display currency',
                      style: const TextStyle(
                        color: _cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.currency_exchange_rounded),
                      onPressed: () async {
                        final chosen = await _pickCurrency(
                          sheetContext,
                          currency,
                          it,
                        );
                        if (chosen != null && sheetContext.mounted) {
                          update(() => currency = chosen);
                        }
                      },
                      label: Text(currency),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      it
                          ? 'Gli importi originali rimangono invariati.'
                          : 'Original amounts remain unchanged.',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      label: it ? 'Ordina le spese' : 'Sort expenses',
                      value: draft.sort,
                      options: {
                        'newest': it ? 'Più recenti' : 'Newest',
                        'oldest': it ? 'Meno recenti' : 'Oldest',
                        'amount-asc': it
                            ? 'Importo crescente'
                            : 'Amount ascending',
                        'amount-desc': it
                            ? 'Importo decrescente'
                            : 'Amount descending',
                      },
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(sort: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: it ? 'Categoria' : 'Category',
                      value: draft.category,
                      options: categories,
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(category: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: it ? 'Stato' : 'Status',
                      value: draft.status,
                      options: {
                        '': it ? 'Tutti gli stati' : 'All statuses',
                        'planned': it ? 'Prevista' : 'Planned',
                        'outstanding': it ? 'Da saldare' : 'Outstanding',
                        'paid': it ? 'Pagata' : 'Paid',
                      },
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(status: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: it ? 'Periodo' : 'Period',
                      value: draft.days.toString(),
                      options: {
                        '0': it ? 'Sempre' : 'Any time',
                        '30': it ? 'Ultimi 30 giorni' : 'Last 30 days',
                        '90': it ? 'Ultimi 90 giorni' : 'Last 90 days',
                      },
                      onChanged: (value) => update(
                        () => draft = draft.copyWith(days: int.parse(value)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => update(() {
                            draft = const BudgetExpenseFilters();
                            currency = tripCurrency;
                          }),
                          child: Text(
                            it ? 'Ripristina' : 'Reset',
                            style: const TextStyle(color: _gold),
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: const Color(0xFF100C0A),
                          ),
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            BudgetDisplayChoice(
                              filters: draft,
                              currency: currency,
                            ),
                          ),
                          child: Text(it ? 'Applica' : 'Apply'),
                        ),
                      ],
                    ),
                    if (draft.sort.startsWith('amount-'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          it
                              ? 'Importi ordinati all’interno della stessa valuta originale.'
                              : 'Amounts sorted within each original currency.',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _field({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: options.containsKey(value) ? value : options.keys.first,
      isExpanded: true,
      dropdownColor: _surface,
      style: const TextStyle(color: _cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _border),
        ),
      ),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
