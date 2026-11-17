// Barra degli strumenti delle spese: valuta di visualizzazione,
// ordinamento e filtri.

import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
import '../../presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import '../../presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'budget_category_picker.dart';
import 'budget_expense_filters.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

class BudgetDisplayChoice {
  const BudgetDisplayChoice({required this.filters, required this.currency});

  final BudgetExpenseFilters filters;
  final String currency;
}

// TODO(audit): file di ~294 righe con soli metodi static di interfaccia: valutare widget separati per valuta, ordinamento e filtri.
abstract final class BudgetExpensesToolbar {
  static const _surface = AmaterasuColors.surfaceRaised;
  static const _border = AmaterasuColors.borderStrong;
  static const _cream = AmaterasuColors.textPrimary;
  static const _muted = AmaterasuColors.textSecondary;
  static const _orange = AmaterasuColors.accentOrange;
  static const _gold = AmaterasuColors.accentGold;

  // TODO(audit): C7 scelta valuta simile in 3 file: valutare un dialogo condiviso.
  static Future<String?> _pickCurrency(
    BuildContext context,
    String selected,
    bool it,
  ) async {
    final supported = CurrencyMinorUnits.supportedCodes.toSet();
    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: budgetL10n(it).btToolbarEn,
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
      backgroundColor: AmaterasuColors.surfaceCard,
      builder: (pickerContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: selected,
          title: budgetL10n(it).btToolbarDisplayCurrency,
          searchHint: budgetL10n(it).btSearchCurrencies,
          noResultsText: budgetL10n(it).btNoCurrenciesFound,
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
      '': budgetL10n(it).btToolbarAllCategories,
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
                      budgetL10n(it).btToolbarFiltersAndDisplay,
                      style: const TextStyle(
                        color: _cream,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      budgetL10n(it).btToolbarCustomizeHowYouView,
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      budgetL10n(it).btToolbarDisplayCurrency,
                      style: const TextStyle(
                        color: _cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.sm),
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
                      budgetL10n(it).btToolbarOriginalAmountsRemainUnchanged,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      label: budgetL10n(it).btToolbarSortExpenses,
                      value: draft.sort,
                      options: {
                        'newest': budgetL10n(it).btToolbarNewest,
                        'oldest': budgetL10n(it).btToolbarOldest,
                        'amount-asc': budgetL10n(it).btToolbarAmountAscending,
                        'amount-desc': budgetL10n(it).btToolbarAmountDescending,
                      },
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(sort: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: budgetL10n(it).btCategoryLabel,
                      value: draft.category,
                      options: categories,
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(category: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: budgetL10n(it).btStatusLabel,
                      value: draft.status,
                      options: {
                        '': budgetL10n(it).btToolbarAllStatuses,
                        'planned': budgetL10n(it).btStatusPlanned,
                        'outstanding': budgetL10n(it).btStatusOutstanding,
                        'paid': budgetL10n(it).btStatusPaid,
                      },
                      onChanged: (value) =>
                          update(() => draft = draft.copyWith(status: value)),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: budgetL10n(it).btToolbarPeriod,
                      value: draft.days.toString(),
                      options: {
                        '0': budgetL10n(it).btToolbarAnyTime,
                        '30': budgetL10n(it).btToolbarLast30Days,
                        '90': budgetL10n(it).btToolbarLast90Days,
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
                            budgetL10n(it).btToolbarReset,
                            style: const TextStyle(color: _gold),
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: AmaterasuColors.surfaceDeep,
                          ),
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            BudgetDisplayChoice(
                              filters: draft,
                              currency: currency,
                            ),
                          ),
                          child: Text(budgetL10n(it).btToolbarApply),
                        ),
                      ],
                    ),
                    if (draft.sort.startsWith('amount-'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          budgetL10n(it).btToolbarAmountsSortedWithinEach,
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
