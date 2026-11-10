import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_history_view.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_dashboard.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expenses_toolbar.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_list.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_user_settlement_summary.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/personal_trip_budget_card.dart';

class TripExpensesPage extends StatefulWidget {
  const TripExpensesPage({super.key, required this.tripId, this.api});

  final String tripId;

  /// Defaults to the Firebase-backed API; replaceable in widget tests.
  final BudgetApi? api;

  @override
  State<TripExpensesPage> createState() => _TripExpensesPageState();
}

class _TripExpensesPageState extends State<TripExpensesPage> {
  late final BudgetApi _api = widget.api ?? BudgetApi(widget.tripId);
  late Future<String> _currency = _api.tripCurrency();
  int _refreshTick = 0;

  void _refresh() {
    setState(() {
      _currency = _api.tripCurrency();
      _refreshTick++;
    });
  }

  bool _showPersonal = false;
  BudgetExpenseFilters _filters = const BudgetExpenseFilters();
  String? _displayCurrency;

  String get _displayPreferenceKey =>
      'amaterasu.b6.summary.${_api.currentUid}.${widget.tripId}';

  @override
  void initState() {
    super.initState();
    _restoreDisplayCurrency();
    // B8.6: keep traveler names inside shared expenses (best effort).
    _api.syncParticipantNames;
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

  static const _background = Color(0xFF100C0A);
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _orange = Color(0xFFD96C32);
  static const _gold = Color(0xFFE3A66C);

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
            seedColor: _orange,
            brightness: Brightness.dark,
          ),
        ),
        child: BudgetCreateDialog(api: _api, currency: currency),
      ),
    );
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 21, color: _gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _cream,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFE17A43) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? _background : _muted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? _background : _muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _cream,
        title: Text(
          l10n.budgetScreenTitle,
          style: const TextStyle(color: _cream, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: _l10n(it).btPageRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: _cream),
          ),
          IconButton(
            tooltip: l10n.b86TripHistory,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BudgetTripHistoryDialog(api: _api),
            ),
            icon: const Icon(Icons.history_rounded, color: _cream),
          ),
          IconButton(
            tooltip: _l10n(it).btPageFilters,
            onPressed: _openExpenseFilters,
            icon: const Icon(Icons.tune_rounded, color: _gold),
          ),
          FutureBuilder<String>(
            future: _currency,
            builder: (context, currencyResult) {
              if (!currencyResult.hasData) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l10n.budgetAddExpense,
                onPressed: () => _addExpense(currencyResult.data!),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: _orange,
                  size: 27,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/trips/${widget.tripId}/more'),
        ),
      ),
      body: FutureBuilder<String>(
        key: ValueKey<int>(_refreshTick),
        future: _currency,
        builder: (context, result) {
          if (result.hasError) {
            return Center(
              child: Text(
                _l10n(it).btPageUnableToLoadTrip,
                style: const TextStyle(color: _cream),
              ),
            );
          }

          if (!result.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currency = result.data!;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final personal = PersonalTripBudgetCard(
                        api: _api,
                        defaultCurrency: currency,
                        displayCurrency: _displayCurrency ?? currency,
                      );
                      final balances = BudgetUserSettlementSummary(
                        api: _api,
                        displayCurrency: _displayCurrency ?? currency,
                      );
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            personal,
                            const SizedBox(height: 20),
                            balances,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: personal),
                          const SizedBox(width: 20),
                          Expanded(child: balances),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  BudgetCategoryDashboard(
                    api: _api,
                    mainCurrency: currency,
                    displayCurrency: _displayCurrency ?? currency,
                    filters: _filters,
                    onFiltersChanged: (value) =>
                        setState(() => _filters = value),
                  ),

                  const SizedBox(height: 28),

                  _sectionHeading(
                    _l10n(it).btPageTripExpenseList,
                    Icons.receipt_long_outlined,
                  ),

                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF241A16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _tab(
                          label: _l10n(it).btPageShared,
                          icon: Icons.groups_outlined,
                          selected: !_showPersonal,
                          onTap: () => setState(() => _showPersonal = false),
                        ),
                        _tab(
                          label: _l10n(it).btPagePersonal,
                          icon: Icons.lock_outline_rounded,
                          selected: _showPersonal,
                          onTap: () => setState(() => _showPersonal = true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  StreamBuilder<Map<String, String>>(
                    stream: _api.budgetCategories(),
                    builder: (context, categories) => BudgetExpenseList(
                      api: _api,
                      private: _showPersonal,
                      displayCurrency: _displayCurrency ?? currency,
                      filters: _filters,
                      categoryNames: categories.data ?? const {},
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
