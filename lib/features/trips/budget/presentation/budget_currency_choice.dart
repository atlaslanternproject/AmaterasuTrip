// Scelta della valuta del budget, usata uguale in tutta l'app: pannello
// dal basso con ricerca tra le valute supportate (nomi da Google, codici
// come riserva) e pulsante a contorno con il codice scelto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/currency/trip_currency_picker_sheet.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'budget_currency.dart';
import 'budget_l10n.dart';

/// Loads the currency names from Google; tests replace it with a fixed
/// list (the app always uses the default).
@visibleForTesting
Future<List<TripCurrency>> Function(String languageCode) budgetCurrencyFetch =
    (languageCode) => const DestinationPlacesService().getCurrencies(
      languageCode: languageCode,
    );

/// Supported currencies with their names (codes only when offline).
Future<List<TripCurrency>> budgetCurrencyChoices(bool it) async {
  final codes = BudgetCurrency.supported.toSet();
  List<TripCurrency> currencies;
  try {
    final fetched = await budgetCurrencyFetch(budgetL10n(it).btCreateEn);
    currencies = fetched
        .where((item) => codes.contains(item.code.toUpperCase()))
        .toList();
    final found = currencies.map((e) => e.code.toUpperCase()).toSet();
    currencies.addAll(
      codes
          .difference(found)
          .map((code) => TripCurrency(code: code, name: code, symbol: code)),
    );
  } catch (_) {
    currencies = codes
        .map((code) => TripCurrency(code: code, name: code, symbol: code))
        .toList();
  }
  currencies.sort((a, b) => a.code.compareTo(b.code));
  return currencies;
}

/// Opens the currency sheet; the chosen code (normalized) or null.
Future<String?> pickBudgetCurrency(
  BuildContext context, {
  required String? selected,
  required String title,
}) async {
  final it = Localizations.localeOf(context).languageCode == 'it';
  final currencies = await budgetCurrencyChoices(it);
  if (!context.mounted) return null;
  final chosen = await showModalBottomSheet<TripCurrency>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AmaterasuColors.surfaceCard,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: TripCurrencyPickerSheet(
        currencies: currencies,
        selectedCurrency: selected,
        title: title,
        searchHint: budgetL10n(it).btSearchCurrencies,
        noResultsText: budgetL10n(it).btNoCurrenciesFound,
      ),
    ),
  );
  return chosen == null ? null : BudgetCurrency.normalize(chosen.code);
}

/// The budget's currency button: "{label}: EUR" with the exchange icon.
class BudgetCurrencyButton extends StatelessWidget {
  const BudgetCurrencyButton({
    super.key,
    required this.currency,
    required this.label,
    required this.onPressed,
  });

  final String currency;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.currency_exchange_rounded),
    label: Text('$label: $currency'),
  );
}
