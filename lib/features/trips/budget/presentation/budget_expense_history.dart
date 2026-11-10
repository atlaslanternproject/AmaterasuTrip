import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../data/budget_fx_service.dart';
import '../data/paths/budget_firestore_paths.dart';
import 'budget_api.dart';

class BudgetExpenseHistory extends StatelessWidget {
  const BudgetExpenseHistory({
    super.key,
    required this.api,
    required this.expenseId,
    required this.private,
  });

  final BudgetApi api;
  final String expenseId;
  final bool private;

  String money(dynamic raw) {
    if (raw is! Map || raw['currency'] is! String || raw['minorUnits'] is! int) {
      return '—';
    }
    try {
      return BudgetMoneyFormatter.format(
        raw['minorUnits'] as int,
        raw['currency'] as String,
      );
    } on ArgumentError {
      return "${raw['minorUnits']} · ${raw['currency']}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final path = private
        ? BudgetFirestorePaths.privateExpense(
            api.tripId,
            api.currentUid,
            expenseId,
          )
        : BudgetFirestorePaths.sharedExpense(api.tripId, expenseId);
    final ref = FirebaseFirestore.instance.doc(path);
    return ExpansionTile(
      title: Text(it ? 'Storico della spesa' : 'Expense history'),
      children: [
        for (final collection in ['revisions', 'fxRateChanges'])
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ref
                .collection(collection)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, result) {
              if (result.hasError) {
                return Text(
                  it ? 'Storico non disponibile' : 'History unavailable',
                );
              }
              if (!result.hasData) return const LinearProgressIndicator();
              return Column(
                children: [
                  for (final doc in result.data!.docs)
                    Builder(
                      builder: (context) {
                        final entry = doc.data();
                        final timestamp = entry['createdAt'];
                        final date = timestamp is Timestamp
                            ? timestamp.toDate()
                            : null;
                        final local = MaterialLocalizations.of(context);
                        final actor = entry['actorUid'] ?? '—';
                        final stamp = date == null
                            ? '—'
                            : '${local.formatMediumDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
                        if (collection == 'fxRateChanges') {
                          final before = BudgetFxQuote.fromLocked(
                            entry['previous'],
                          );
                          final next = BudgetFxQuote.fromLocked(entry['next']);
                          return ListTile(
                            title: Text(
                              '${next?.base}/${next?.quote} · ${before?.rate ?? "—"} → ${next?.rate ?? "—"}',
                            ),
                            subtitle: Text(
                              '$stamp · $actor\n${entry['reason'] ?? ""}',
                            ),
                          );
                        }
                        final snapshot = entry['snapshot'];
                        if (snapshot is! Map) return const SizedBox.shrink();
                        final details = <String>['$stamp · $actor'];
                        for (final key in ['shares', 'advances']) {
                          final values = snapshot[key];
                          if (values is! Map) continue;
                          final label = key == 'shares'
                              ? (it ? 'Quota' : 'Share')
                              : (it ? 'Anticipo' : 'Advance');
                          for (final value in values.entries) {
                            details.add(
                              '$label · ${value.key} · ${money(value.value)}',
                            );
                          }
                        }
                        final accounts = entry['accountPayments'];
                        if (accounts is List) {
                          for (final payment in accounts.whereType<Map>()) {
                            final currency = payment['accountCurrency'];
                            final debit = payment['accountDebitMinor'];
                            details.add(
                              '${it ? "Conto" : "Account"} · ${payment['payerUid']} · ${debit == null ? currency : money({'currency': currency, 'minorUnits': debit})}',
                            );
                          }
                        }
                        return ListTile(
                          title: Text(
                            '${it ? "Revisione" : "Revision"} ${entry['number']} · ${money(snapshot['total'])}',
                          ),
                          subtitle: Text(details.join('\n')),
                        );
                      },
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
