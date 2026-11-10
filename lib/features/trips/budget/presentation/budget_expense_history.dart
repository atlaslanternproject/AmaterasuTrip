import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/budget_money_formatter.dart';
import '../data/budget_fx_service.dart';
import 'budget_api.dart';
import 'budget_history_view.dart';
import 'budget_people.dart';

class BudgetExpenseHistory extends StatelessWidget {
  const BudgetExpenseHistory({
    super.key,
    required this.api,
    required this.expenseId,
    required this.private,
    this.expense,
  });

  final BudgetApi api;
  final String expenseId;
  final bool private;

  /// The expense document, used for names recorded in it (B8.6).
  final Map<String, dynamic>? expense;

  String money(dynamic raw) {
    if (raw is! Map ||
        raw['currency'] is! String ||
        raw['minorUnits'] is! int) {
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
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(l10n.b86ExpenseHistory),
      children: [
        // B8.6: every operation, including reimbursements, decisions,
        // debt closures and cancellations.
        BudgetHistoryList(api: api, expenseId: expenseId, private: private),
        const Divider(),
        FutureBuilder<Map<String, String>>(
          future: api.travelerNameMap.catchError(
            (Object _) => <String, String>{},
          ),
          builder: (context, namesResult) {
            final live = namesResult.data ?? const <String, String>{};
            String person(Object? uid) => uid is String
                ? BudgetPeople.name(
                    uid,
                    live: live,
                    expense: expense,
                    fallback: l10n.b86FormerTraveler,
                  )
                : '—';
            return Column(
              children: [
                for (final collection in ['revisions', 'fxRateChanges'])
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: api.expenseRecords(
                      expenseId,
                      private: private,
                      collection: collection,
                    ),
                    builder: (context, result) {
                      if (result.hasError) {
                        return Text(
                          it
                              ? 'Storico non disponibile'
                              : 'History unavailable',
                        );
                      }
                      if (!result.hasData) {
                        return const LinearProgressIndicator();
                      }
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
                                final actor = person(entry['actorUid']);
                                final stamp = date == null
                                    ? '—'
                                    : '${local.formatMediumDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
                                if (collection == 'fxRateChanges') {
                                  final before = BudgetFxQuote.fromLocked(
                                    entry['previous'],
                                  );
                                  final next = BudgetFxQuote.fromLocked(
                                    entry['next'],
                                  );
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
                                if (snapshot is! Map) {
                                  return const SizedBox.shrink();
                                }
                                final details = <String>['$stamp · $actor'];
                                for (final key in ['shares', 'advances']) {
                                  final values = snapshot[key];
                                  if (values is! Map) continue;
                                  final label = key == 'shares'
                                      ? (it ? 'Quota' : 'Share')
                                      : (it ? 'Anticipo' : 'Advance');
                                  for (final value in values.entries) {
                                    details.add(
                                      '$label · ${person(value.key)} · ${money(value.value)}',
                                    );
                                  }
                                }
                                final accounts = entry['accountPayments'];
                                if (accounts is List) {
                                  for (final payment
                                      in accounts.whereType<Map>()) {
                                    final currency = payment['accountCurrency'];
                                    final debit = payment['accountDebitMinor'];
                                    details.add(
                                      '${it ? "Conto" : "Account"} · ${person(payment['payerUid'])} · ${debit == null ? currency : money({'currency': currency, 'minorUnits': debit})}',
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
          },
        ),
      ],
    );
  }
}
