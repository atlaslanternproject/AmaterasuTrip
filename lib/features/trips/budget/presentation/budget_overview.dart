import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'budget_api.dart';

class BudgetOverview extends StatelessWidget {
  const BudgetOverview({super.key, required this.api});

  final BudgetApi api;

  String _amount(int minorUnits, String currency) {
    try {
      return BudgetMoneyFormatter.format(
        minorUnits,
        currency,
        decimalSeparator: '.',
      );
    } catch (_) {
      return '$minorUnits unità minime · $currency';
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: api.sharedExpenses(),
      builder: (context, shared) {
        if (shared.hasError) {
          return Text(
            '${it ? "Errore riepilogo" : "Overview error"}: ${shared.error}',
          );
        }

        if (!shared.hasData) {
          return const LinearProgressIndicator();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: api.privateExpenses(),
          builder: (context, personal) {
            if (personal.hasError) {
              return Text(
                '${it ? "Errore riepilogo" : "Overview error"}: ${personal.error}',
              );
            }

            if (!personal.hasData) {
              return const LinearProgressIndicator();
            }

            final totals = <String, List<int>>{};
            var expenseCount = 0;

            for (final doc in [...shared.data!.docs, ...personal.data!.docs]) {
              final data = doc.data();

              if (data['lifecycle'] == 'cancelled') continue;

              final snapshot = data['snapshot'];
              if (snapshot is! Map) continue;

              final total = snapshot['total'];
              if (total is! Map) continue;

              final currency = total['currency'];
              final amount = total['minorUnits'];

              if (currency is! String || amount is! int) continue;

              var paid = 0;
              final advances = snapshot['advances'];

              if (advances is Map) {
                for (final value in advances.values) {
                  if (value is Map && value['minorUnits'] is int) {
                    paid += value['minorUnits'] as int;
                  }
                }
              }

              final row = totals.putIfAbsent(currency, () => <int>[0, 0, 0]);

              row[0] += amount;
              row[1] += paid;
              row[2] += amount - paid;
              expenseCount++;
            }

            final currencies = totals.keys.toList()..sort();

            return Card(
              color: const Color(0xFF241A16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it ? 'Riepilogo contabile' : 'Financial overview',
                      style: const TextStyle(
                        color: Color(0xFFF2E7D5),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${it ? "Spese registrate" : "Recorded expenses"}: $expenseCount',
                      style: const TextStyle(color: Color(0xFFB7A99B)),
                    ),
                    if (currencies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          it ? 'Nessuna spesa.' : 'No expenses.',
                          style: const TextStyle(color: Color(0xFFB7A99B)),
                        ),
                      ),
                    for (final currency in currencies) ...[
                      const Divider(),
                      Text(
                        currency,
                        style: const TextStyle(
                          color: Color(0xFFE3A66C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${it ? "Totale" : "Total"}: ${_amount(totals[currency]![0], currency)}',
                      ),
                      Text(
                        '${it ? "Anticipato" : "Advanced"}: ${_amount(totals[currency]![1], currency)}',
                      ),
                      Text(
                        '${it ? "Da saldare" : "Outstanding"}: ${_amount(totals[currency]![2], currency)}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      it
                          ? 'Importi separati per valuta, senza conversioni automatiche.'
                          : 'Amounts separated by currency, without automatic conversion.',
                      style: const TextStyle(
                        color: Color(0xFFB7A99B),
                        fontSize: 12,
                      ),
                    ),
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
