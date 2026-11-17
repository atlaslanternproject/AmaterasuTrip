part of 'personal_trip_budget_card.dart';

extension _PersonalTripBudgetCardStateCurrency on _PersonalTripBudgetCardState {
  String _editableAmount(PersonalTripBudget budget) {
    return BudgetMoneyFormatter.format(
      budget.amountMinor,
      budget.currency,
      includeCurrency: false,
    );
  }

  Future<String?> _pickCurrency(
    BuildContext dialogContext,
    String selected,
  ) async {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final supported = BudgetCurrency.supported.toSet();

    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: budgetL10n(it).btPersonalEn,
      );

      currencies = fetched
          .where((item) => supported.contains(item.code.toUpperCase()))
          .toList();

      final found = currencies.map((item) => item.code.toUpperCase()).toSet();

      currencies.addAll(
        supported
            .difference(found)
            .map((code) => TripCurrency(code: code, name: code, symbol: code)),
      );
    } catch (_) {
      currencies = supported
          .map((code) => TripCurrency(code: code, name: code, symbol: code))
          .toList();
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    if (!dialogContext.mounted) return null;

    final chosen = await showModalBottomSheet<TripCurrency>(
      context: dialogContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AmaterasuColors.surfaceCard,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: selected,
          title: budgetL10n(it).btPersonalBudgetCurrency,
          searchHint: budgetL10n(it).btSearchCurrencies,
          noResultsText: budgetL10n(it).btNoCurrenciesFound,
        ),
      ),
    );

    if (chosen == null) return null;

    return BudgetCurrency.normalize(chosen.code);
  }

  String _friendlyError(Object error, bool it) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return budgetL10n(it).btPersonalFirestoreDeniedTheWrite;
    }

    if (error is ArgumentError || error is FormatException) {
      return budgetL10n(it).btPersonalInvalidAmountOrCurrency;
    }

    return budgetL10n(it).btPersonalOperationFailed(error);
  }
}
