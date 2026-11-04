import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_dashboard.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_list.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_user_settlement_summary.dart';

class TripExpensesPage extends StatefulWidget {
  const TripExpensesPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripExpensesPage> createState() => _TripExpensesPageState();
}

class _TripExpensesPageState extends State<TripExpensesPage> {
  late final BudgetApi _api = BudgetApi(widget.tripId);
  late final Future<String> _currency = _api.tripCurrency();

  bool _showPersonal = false;
  BudgetExpenseFilters _filters = const BudgetExpenseFilters();

  static const _background = Color(0xFF100C0A);
  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _orange = Color(0xFFD96C32);
  static const _gold = Color(0xFFE3A66C);

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
        title: Text(l10n.budgetScreenTitle),
        actions: [
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
                  size: 28,
                  color: Color(0xFFE3A66C),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/trips/${widget.tripId}/more'),
        ),
      ),
      body: FutureBuilder<String>(
        future: _currency,
        builder: (context, result) {
          if (result.hasError) {
            return Center(
              child: Text(
                it
                    ? 'Impossibile caricare il viaggio.'
                    : 'Unable to load trip.',
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public_outlined,
                          size: 17,
                          color: Color(0xFFB7A99B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.budgetTripCurrency(currency),
                          style: const TextStyle(
                            color: Color(0xFFB7A99B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _sectionHeading(
                    it ? 'La tua situazione' : 'Your finances',
                    Icons.account_balance_wallet_outlined,
                  ),
                  BudgetUserSettlementSummary(api: _api),

                  const SizedBox(height: 26),

                  BudgetCategoryDashboard(
                    api: _api,
                    mainCurrency: currency,
                    filters: _filters,
                    onFiltersChanged: (value) =>
                        setState(() => _filters = value),
                  ),

                  const SizedBox(height: 28),

                  _sectionHeading(
                    it ? 'Le spese del viaggio' : 'Trip expense list',
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
                          label: it ? 'Condivise' : 'Shared',
                          icon: Icons.groups_outlined,
                          selected: !_showPersonal,
                          onTap: () => setState(() => _showPersonal = false),
                        ),
                        _tab(
                          label: it ? 'Personali' : 'Personal',
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
