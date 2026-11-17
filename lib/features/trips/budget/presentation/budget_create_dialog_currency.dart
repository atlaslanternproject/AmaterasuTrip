// Parte di budget_create_dialog.dart: scelta della valuta
// e nomi dei viaggiatori.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_create_dialog.dart';

extension _BudgetCreateDialogStateCurrency on _BudgetCreateDialogState {
  // TODO(audit): C7 scelta valuta simile in 3 file (create, toolbar, budget personale): valutare un dialogo condiviso.
  Future<void> _pickCurrency() async {
    if (_saving) return;

    final it = Localizations.localeOf(context).languageCode == 'it';
    final codes = BudgetCurrency.supported.toSet();
    List<TripCurrency> currencies;

    try {
      final fetched = await const DestinationPlacesService().getCurrencies(
        languageCode: budgetL10n(it).btCreateEn,
      );

      currencies = fetched.where((item) {
        return codes.contains(item.code.toUpperCase());
      }).toList();

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

    if (!mounted) return;

    final chosen = await showModalBottomSheet<TripCurrency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AmaterasuColors.surfaceCard,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TripCurrencyPickerSheet(
          currencies: currencies,
          selectedCurrency: _selectedCurrency,
          title: budgetL10n(it).btCreateExpenseCurrency,
          searchHint: budgetL10n(it).btSearchCurrencies,
          noResultsText: budgetL10n(it).btNoCurrenciesFound,
        ),
      ),
    );

    if (!mounted || chosen == null) return;

    final code = BudgetCurrency.normalize(chosen.code);

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
