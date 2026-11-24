// Parte di budget_create_dialog.dart: scelta della valuta
// e nomi dei viaggiatori.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_create_dialog.dart';

extension _BudgetCreateDialogStateCurrency on _BudgetCreateDialogState {
  // TODO(audit): C7 il dialogo spese usa budget_currency_choice.dart; toolbar e budget personale hanno ancora la loro copia.
  Future<void> _pickCurrency() async {
    if (_saving) return;

    final it = Localizations.localeOf(context).languageCode == 'it';
    final code = await pickBudgetCurrency(
      context,
      selected: _selectedCurrency,
      title: budgetL10n(it).btCreateExpenseCurrency,
    );
    if (!mounted || code == null) return;

    if (code != _selectedCurrency) {
      setState(() {
        _selectedCurrency = code;
        _paymentAllocations = [];
        _amount.clear();
        for (final controller in _shareInputs.values) {
          controller.clear();
        }
        _error = null;
      });
    }
  }

  String _travelerName(String uid, bool it) {
    if (uid == widget.api.currentUid) {
      return budgetL10n(it).btCreateYou;
    }

    for (final traveler in _travelers) {
      if (traveler['uid'] == uid) {
        return traveler['name'] ?? (budgetL10n(it).btCreateTraveler);
      }
    }

    return uid;
  }
}
