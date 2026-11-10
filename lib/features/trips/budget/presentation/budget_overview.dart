import '../calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
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
          return Text('${_l10n(it).btOverviewOverviewError}: ${shared.error}');
        }

        if (!shared.hasData) {
          return const LinearProgressIndicator();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: api.privateExpenses(),
          builder: (context, personal) {
            if (personal.hasError) {
              return Text(
                '${_l10n(it).btOverviewOverviewError}: ${personal.error}',
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
                      _l10n(it).btOverviewFinancialOverview,
                      style: const TextStyle(
                        color: Color(0xFFF2E7D5),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_l10n(it).btOverviewRecordedExpenses}: $expenseCount',
                      style: const TextStyle(color: Color(0xFFB7A99B)),
                    ),
                    if (currencies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _l10n(it).btOverviewNoExpenses,
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
                        '${_l10n(it).btOverviewTotal}: ${_amount(totals[currency]![0], currency)}',
                      ),
                      Text(
                        '${_l10n(it).btOverviewAdvanced}: ${_amount(totals[currency]![1], currency)}',
                      ),
                      Text(
                        '${_l10n(it).btOverviewOutstanding}: ${_amount(totals[currency]![2], currency)}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _l10n(it).btOverviewAmountsSeparatedByCurrency,
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

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
