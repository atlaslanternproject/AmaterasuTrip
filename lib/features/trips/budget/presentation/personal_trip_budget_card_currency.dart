// Parte di personal_trip_budget_card.dart: scelta della valuta
// e messaggi di errore.

part of 'personal_trip_budget_card.dart';

extension _PersonalTripBudgetCardStateCurrency on _PersonalTripBudgetCardState {
  String _editableAmount(PersonalTripBudget budget) {
    return BudgetMoneyFormatter.format(
      budget.amountMinor,
      budget.currency,
      includeCurrency: false,
    );
  }

  // Shared currency sheet of the budget (COERENZA G3, was a copy).
  Future<String?> _pickCurrency(BuildContext dialogContext, String selected) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    return pickBudgetCurrency(
      dialogContext,
      selected: selected,
      title: budgetL10n(it).btPersonalBudgetCurrency,
      useRootNavigator: true,
    );
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
