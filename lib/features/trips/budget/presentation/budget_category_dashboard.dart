import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
import 'budget_api.dart';

class BudgetCategoryDashboard extends StatelessWidget {
  const BudgetCategoryDashboard({
    super.key,
    required this.api,
    required this.mainCurrency,
  });

  final BudgetApi api;
  final String mainCurrency;

  static const _labelsIt = <String, String>{
    'accommodation': 'Alloggio',
    'food': 'Cibo e bevande',
    'transport': 'Trasporti',
    'activities': 'Attività',
    'shopping': 'Shopping',
    'other': 'Altro',
  };

  static const _labelsEn = <String, String>{
    'accommodation': 'Accommodation',
    'food': 'Food & drinks',
    'transport': 'Transport',
    'activities': 'Activities',
    'shopping': 'Shopping',
    'other': 'Other',
  };

  String _label(String raw, bool it) {
    final labels = it ? _labelsIt : _labelsEn;
    if (labels.containsKey(raw)) {
      return labels[raw]!;
    }

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return it ? 'Altro' : 'Other';
    }

    return normalized;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  String _money(int minorUnits, String currency) {
    final decimals = CurrencyMinorUnits.decimals(currency);
    final factor = CurrencyMinorUnits.factor(currency);
    final negative = minorUnits < 0 ? '-' : '';
    final absolute = minorUnits.abs();
    final whole = absolute ~/ factor;

    if (decimals == 0) {
      return '$negative$whole $currency';
    }

    final fraction = (absolute % factor).toString().padLeft(decimals, '0');
    return '$negative$whole,$fraction $currency';
  }

  @override
  Widget build(BuildContext context) {
    final isIt = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: api.sharedExpenses(),
      builder: (context, sharedSnapshot) {
        if (sharedSnapshot.hasError) {
          return Text(
            isIt
                ? 'Errore nel caricamento delle spese condivise.'
                : 'Unable to load shared expenses.',
          );
        }

        if (!sharedSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: api.privateExpenses(),
          builder: (context, privateSnapshot) {
            if (privateSnapshot.hasError) {
              return Text(
                isIt
                    ? 'Errore nel caricamento delle spese personali.'
                    : 'Unable to load personal expenses.',
              );
            }

            if (!privateSnapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final categories = <String, int>{};
            final excludedCurrencies = <String, int>{};
            var total = 0;
            var paid = 0;
            var excludedCount = 0;

            final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
              ...sharedSnapshot.data!.docs,
              ...privateSnapshot.data!.docs,
            ];

            for (final doc in docs) {
              final data = doc.data();

              if (data['lifecycle'] == 'cancelled') {
                continue;
              }

              final snapshot = _map(data['snapshot']);
              final totalMap = _map(snapshot['total']);

              final currency = totalMap['currency']?.toString();
              final amount = totalMap['minorUnits'];

              if (currency == null || amount is! int || amount < 0) {
                continue;
              }

              if (currency != mainCurrency) {
                excludedCount++;
                excludedCurrencies[currency] =
                    (excludedCurrencies[currency] ?? 0) + amount;
                continue;
              }

              final rawCategory = (data['category']?.toString() ?? 'other')
                  .trim();
              final category = rawCategory.isEmpty ? 'other' : rawCategory;

              categories[category] = (categories[category] ?? 0) + amount;
              total += amount;

              final advances = _map(snapshot['advances']);
              var paidForExpense = 0;

              for (final advance in advances.values) {
                final map = _map(advance);
                if (map['currency'] == currency && map['minorUnits'] is int) {
                  paidForExpense += map['minorUnits'] as int;
                }
              }

              paid += paidForExpense;
            }

            final ordered = categories.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Card(
              color: const Color(0xFF241A16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIt
                          ? 'Distribuzione delle spese'
                          : 'Expense distribution',
                      style: const TextStyle(
                        color: Color(0xFFF2E7D5),
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIt
                          ? 'Valuta del riepilogo: $mainCurrency'
                          : 'Summary currency: $mainCurrency',
                      style: const TextStyle(
                        color: Color(0xFFB7A99B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _money(total, mainCurrency),
                      style: const TextStyle(
                        color: Color(0xFFF2E7D5),
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIt
                          ? 'Totale registrato nella valuta principale del viaggio'
                          : 'Recorded total in the trip main currency',
                      style: const TextStyle(
                        color: Color(0xFFB7A99B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${isIt ? "Pagato ai fornitori" : "Paid to suppliers"}: ${_money(paid, mainCurrency)}',
                      style: const TextStyle(color: Color(0xFFF2E7D5)),
                    ),
                    Text(
                      '${isIt ? "Ancora da pagare" : "Still to pay"}: ${_money(total - paid, mainCurrency)}',
                      style: const TextStyle(color: Color(0xFFE3A66C)),
                    ),
                    const Divider(height: 26),
                    if (ordered.isEmpty)
                      Text(
                        isIt
                            ? 'Nessuna spesa disponibile per il grafico.'
                            : 'No expenses available for the chart.',
                        style: const TextStyle(color: Color(0xFFB7A99B)),
                      ),
                    for (final entry in ordered) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(entry.key, isIt),
                              style: const TextStyle(
                                color: Color(0xFFF2E7D5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _money(entry.value, mainCurrency),
                            style: const TextStyle(
                              color: Color(0xFFE3A66C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: total > 0
                              ? (entry.value / total).clamp(0.0, 1.0)
                              : 0,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF49312B),
                          color: const Color(0xFFE17A43),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (excludedCurrencies.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        isIt
                            ? 'Alcune spese in altre valute sono escluse temporaneamente dal grafico finché non applichiamo i tassi storici verificati.'
                            : 'Some expenses in other currencies are temporarily excluded until verified historical rates are applied.',
                        style: const TextStyle(
                          color: Color(0xFFB7A99B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final entry
                          in excludedCurrencies.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key)))
                        Text(
                          '${entry.key}: ${_money(entry.value, entry.key)}',
                          style: const TextStyle(
                            color: Color(0xFFE3A66C),
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        isIt
                            ? '$excludedCount spese escluse dal grafico.'
                            : '$excludedCount expenses excluded from the chart.',
                        style: const TextStyle(
                          color: Color(0xFFB7A99B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
