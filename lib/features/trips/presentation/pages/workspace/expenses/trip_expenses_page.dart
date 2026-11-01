import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_api.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_list.dart';

import 'package:amaterasutrip/features/trips/budget/presentation/budget_overview.dart';

class TripExpensesPage extends StatefulWidget {
  const TripExpensesPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripExpensesPage> createState() => _TripExpensesPageState();
}

class _TripExpensesPageState extends State<TripExpensesPage> {
  late final BudgetApi _api = BudgetApi(widget.tripId);
  late final Future<String> _currency = _api.tripCurrency();

  Future<void> _add(String currency) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD96C32),
            brightness: Brightness.dark,
          ),
        ),
        child: BudgetCreateDialog(api: _api, currency: currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return Scaffold(
      backgroundColor: const Color(0xFF100C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C0A),
        foregroundColor: const Color(0xFFF2E7D5),
        title: Text(it ? 'Budget e Spese' : 'Budget & Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/trips/${widget.tripId}/more'),
        ),
      ),
      body: FutureBuilder<String>(
        future: _currency,
        builder: (context, currencySnapshot) {
          if (currencySnapshot.hasError) {
            return Center(
              child: Text(
                '${it ? "Impossibile caricare il viaggio" : "Unable to load trip"}'
                ': ${currencySnapshot.error}',
              ),
            );
          }

          if (!currencySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currency = currencySnapshot.data!;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it ? 'Le spese del viaggio' : 'Trip expenses',
                            style: const TextStyle(
                              color: Color(0xFFF2E7D5),
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${it ? "Valuta principale" : "Main currency"}: $currency',
                            style: const TextStyle(color: Color(0xFFB7A99B)),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _add(currency),
                        icon: const Icon(Icons.add),
                        label: Text(it ? 'Aggiungi spesa' : 'Add expense'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD96C32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    it ? 'Spese condivise' : 'Shared expenses',
                    style: const TextStyle(
                      color: Color(0xFFF2E7D5),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BudgetOverview(api: _api),
                  const SizedBox(height: 12),
                  BudgetExpenseList(api: _api, private: false),
                  const SizedBox(height: 28),
                  Text(
                    it ? 'Le mie spese personali' : 'My personal expenses',
                    style: const TextStyle(
                      color: Color(0xFFF2E7D5),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BudgetExpenseList(api: _api, private: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
