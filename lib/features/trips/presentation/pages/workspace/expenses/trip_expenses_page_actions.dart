// Parte di trip_expenses_page.dart: azioni della pagina
// (aggiornamento, valuta, filtri, nuova spesa).

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_expenses_page.dart';

extension _TripExpensesPageStateActions on _TripExpensesPageState {
  void _refresh() {
    setState(() {
      _currency = _api.tripCurrency();
      _refreshTick++;
    });
  }

  Future<void> _restoreDisplayCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_displayPreferenceKey);
      if (stored != null && stored.length == 3 && mounted) {
        setState(() => _displayCurrency = stored);
      }
    } catch (_) {
      // Preference unavailable: trip currency remains the default.
    }
  }

  Future<void> _setDisplayCurrency(String value) async {
    setState(() => _displayCurrency = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayPreferenceKey, value);
    } catch (_) {
      // Keep the selection active for this session.
    }
  }

  Future<void> _openExpenseFilters() async {
    Map<String, String> categories;

    try {
      categories = await _api.budgetCategories().first;
    } catch (_) {
      categories = <String, String>{};
    }

    String tripCurrency;

    try {
      tripCurrency = await _currency;
    } catch (_) {
      return;
    }

    if (!mounted) return;

    final selected = await BudgetExpensesToolbar.chooseFilters(
      context,
      filters: _filters,
      categoryNames: categories,
      displayCurrency: _displayCurrency ?? tripCurrency,
      tripCurrency: tripCurrency,
    );

    if (!mounted || selected == null) return;

    setState(() => _filters = selected.filters);

    if (_displayCurrency != selected.currency) {
      await _setDisplayCurrency(selected.currency);
    }
  }

  Future<void> _addExpense(String currency) async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: Theme.of(dialogContext).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _TripExpensesPageState._orange,
            brightness: Brightness.dark,
          ),
        ),
        child: BudgetCreateDialog(api: _api, currency: currency),
      ),
    );
  }
}
