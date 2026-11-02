import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/currency_minor_units.dart';
import 'budget_api.dart';

class BudgetUserSettlementSummary extends StatefulWidget {
  const BudgetUserSettlementSummary({super.key, required this.api});

  final BudgetApi api;

  @override
  State<BudgetUserSettlementSummary> createState() =>
      _BudgetUserSettlementSummaryState();
}

class _DebtLine {
  const _DebtLine(this.debtor, this.creditor, this.amount);
  final String debtor;
  final String creditor;
  final int amount;
}

class _Movement {
  const _Movement({
    required this.debtor,
    required this.creditor,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.expenseTitle,
  });

  final String debtor;
  final String creditor;
  final int amount;
  final String currency;
  final String status;
  final DateTime? date;
  final String expenseTitle;
}

class _BudgetUserSettlementSummaryState
    extends State<BudgetUserSettlementSummary> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSub;

  final _refundSubs =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  final _expenses = <String, Map<String, dynamic>>{};
  final _refunds = <String, List<Map<String, dynamic>>>{};
  final _loadedRefundIds = <String>{};

  late Future<Map<String, String>> _names;

  bool _loading = true;
  bool _showMovements = false;
  String? _error;

  static const _cream = Color(0xFFF2E7D5);
  static const _muted = Color(0xFFB7A99B);
  static const _gold = Color(0xFFE3A66C);

  @override
  void initState() {
    super.initState();
    _names = widget.api.travelerNameMap;
    _listen();
  }

  @override
  void didUpdateWidget(covariant BudgetUserSettlementSummary oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.api.tripId != widget.api.tripId) {
      _expensesSub?.cancel();
      for (final sub in _refundSubs.values) {
        sub.cancel();
      }
      _refundSubs.clear();
      _refunds.clear();
      _expenses.clear();
      _loadedRefundIds.clear();
      _loading = true;
      _error = null;
      _names = widget.api.travelerNameMap;
      _listen();
    }
  }

  void _listen() {
    _expensesSub = widget.api.sharedExpenses().listen(
      (result) {
        if (!mounted) return;

        final current = <String>{};

        for (final doc in result.docs) {
          final data = doc.data();
          if (data['lifecycle'] == 'cancelled') continue;

          current.add(doc.id);
          _expenses[doc.id] = data;

          if (!_refundSubs.containsKey(doc.id)) {
            final id = doc.id;

            _refundSubs[id] = FirebaseFirestore.instance
                .collection('trips')
                .doc(widget.api.tripId)
                .collection('budgetSharedExpenses')
                .doc(id)
                .collection('reimbursements')
                .snapshots()
                .listen(
                  (refunds) {
                    if (!mounted) return;
                    setState(() {
                      _refunds[id] = refunds.docs
                          .map((item) => item.data())
                          .toList();
                      _loadedRefundIds.add(id);
                    });
                  },
                  onError: (Object error) {
                    if (!mounted) return;
                    setState(() => _error = error.toString());
                  },
                );
          }
        }

        for (final id in _expenses.keys.toList()) {
          if (!current.contains(id)) {
            _expenses.remove(id);
            _refunds.remove(id);
            _loadedRefundIds.remove(id);
            _refundSubs.remove(id)?.cancel();
          }
        }

        setState(() => _loading = false);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    for (final sub in _refundSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  int _amount(dynamic value) {
    final raw = _asMap(value)['minorUnits'];
    return raw is int ? raw : 0;
  }

  String _money(int minor, String currency) {
    try {
      final decimals = CurrencyMinorUnits.decimals(currency);
      final factor = CurrencyMinorUnits.factor(currency);
      final absolute = minor.abs();
      final whole = absolute ~/ factor;
      final sign = minor < 0 ? '-' : '';

      if (decimals == 0) return '$sign$whole $currency';

      final fraction = (absolute % factor).toString().padLeft(decimals, '0');

      return '$sign$whole,$fraction $currency';
    } catch (_) {
      return '$minor $currency';
    }
  }

  List<_DebtLine> _debts(Map<String, dynamic> snapshot) {
    if (snapshot['status'] != 'paid') return [];

    final shares = _asMap(snapshot['shares']);
    final advances = _asMap(snapshot['advances']);

    final ids = {...shares.keys, ...advances.keys}.toList()..sort();
    final debtors = <String, int>{};
    final creditors = <String, int>{};

    for (final uid in ids) {
      final net = _amount(advances[uid]) - _amount(shares[uid]);
      if (net < 0) debtors[uid] = -net;
      if (net > 0) creditors[uid] = net;
    }

    final lines = <_DebtLine>[];

    for (final debtor in debtors.keys) {
      var remaining = debtors[debtor]!;

      for (final creditor in creditors.keys) {
        final available = creditors[creditor]!;
        final allocated = math.min(remaining, available);

        if (allocated <= 0) continue;

        lines.add(_DebtLine(debtor, creditor, allocated));
        remaining -= allocated;
        creditors[creditor] = available - allocated;
      }
    }

    return lines;
  }

  String _person(String uid, Map<String, String> names) {
    return names[uid] ?? '—';
  }

  Widget _heading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _cream,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_error != null) {
      return Text(
        l10n.budgetBalanceLoadError,
        style: const TextStyle(color: _muted),
      );
    }

    if (_loading || !_expenses.keys.every(_loadedRefundIds.contains)) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: LinearProgressIndicator(),
      );
    }

    return FutureBuilder<Map<String, String>>(
      future: _names,
      builder: (context, namesResult) {
        if (namesResult.hasError) {
          return Text(
            l10n.budgetNamesUnavailable,
            style: const TextStyle(color: _muted),
          );
        }

        if (!namesResult.hasData) {
          return const LinearProgressIndicator();
        }

        final names = namesResult.data!;
        final uid = widget.api.currentUid;

        final incoming = <String, Map<String, int>>{};
        final outgoing = <String, Map<String, int>>{};
        final incomingPending = <String, Map<String, int>>{};
        final outgoingPending = <String, Map<String, int>>{};
        final movements = <_Movement>[];

        void add(
          Map<String, Map<String, int>> target,
          String currency,
          String person,
          int amount,
        ) {
          if (amount <= 0) return;
          final map = target.putIfAbsent(currency, () => {});
          map[person] = (map[person] ?? 0) + amount;
        }

        for (final expense in _expenses.entries) {
          final data = expense.value;
          final snapshot = _asMap(data['snapshot']);
          final currency =
              _asMap(snapshot['total'])['currency']?.toString() ?? 'EUR';
          final refunds = _refunds[expense.key] ?? [];

          for (final refund in refunds) {
            final debtor = refund['debtorUid']?.toString() ?? '';
            final creditor = refund['creditorUid']?.toString() ?? '';
            final amount = refund['minorUnits'];

            if (debtor != uid && creditor != uid) continue;
            if (amount is! int || amount <= 0) continue;

            final timestamp = refund['createdAt'];
            movements.add(
              _Movement(
                debtor: debtor,
                creditor: creditor,
                amount: amount,
                currency: currency,
                status: refund['status']?.toString() ?? 'pending',
                date: timestamp is Timestamp ? timestamp.toDate() : null,
                expenseTitle: data['title']?.toString() ?? '',
              ),
            );
          }

          for (final debt in _debts(snapshot)) {
            var confirmed = 0;
            var pending = 0;

            for (final refund in refunds) {
              if (refund['debtorUid'] != debt.debtor ||
                  refund['creditorUid'] != debt.creditor) {
                continue;
              }

              final amount = refund['minorUnits'];
              if (amount is! int || amount <= 0) continue;

              if (refund['status'] == 'confirmed') {
                confirmed += amount;
              } else if (refund['status'] == 'pending') {
                pending += amount;
              }
            }

            final remaining = math.max(0, debt.amount - confirmed);
            final waiting = math.min(remaining, pending);

            if (debt.creditor == uid) {
              add(incoming, currency, debt.debtor, remaining);
              add(incomingPending, currency, debt.debtor, waiting);
            }

            if (debt.debtor == uid) {
              add(outgoing, currency, debt.creditor, remaining);
              add(outgoingPending, currency, debt.creditor, waiting);
            }
          }
        }

        movements.sort((a, b) {
          final aDate = a.date;
          final bDate = b.date;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        Widget balanceGroup(
          String title,
          String emptyText,
          Map<String, Map<String, int>> amounts,
          Map<String, Map<String, int>> pending,
        ) {
          final rows = <({String currency, String person, int value})>[];

          for (final entry in amounts.entries) {
            for (final person in entry.value.entries) {
              if (person.value > 0) {
                rows.add((
                  currency: entry.key,
                  person: person.key,
                  value: person.value,
                ));
              }
            }
          }

          rows.sort((a, b) {
            final currency = a.currency.compareTo(b.currency);
            return currency != 0 ? currency : a.person.compareTo(b.person);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading(title),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                Text(emptyText, style: const TextStyle(color: _muted)),
              for (final row in rows) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _person(row.person, names),
                        style: const TextStyle(color: _cream),
                      ),
                    ),
                    Text(
                      _money(row.value, row.currency),
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if ((pending[row.currency]?[row.person] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${l10n.budgetPendingConfirmation}: '
                      '${_money(pending[row.currency]![row.person]!, row.currency)}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        String statusText(String status) {
          switch (status) {
            case 'confirmed':
              return l10n.budgetMovementConfirmed;
            case 'rejected':
              return l10n.budgetMovementRejected;
            default:
              return l10n.budgetMovementPending;
          }
        }

        return Card(
          color: const Color(0xFF241A16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetYourBalance,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                balanceGroup(
                  l10n.budgetOthersOweYou,
                  l10n.budgetNothingToReceive,
                  incoming,
                  incomingPending,
                ),
                const Divider(color: Color(0xFF49342B), height: 26),
                balanceGroup(
                  l10n.budgetYouOwe,
                  l10n.budgetNothingToPay,
                  outgoing,
                  outgoingPending,
                ),
                const Divider(color: Color(0xFF49342B), height: 26),
                InkWell(
                  onTap: () {
                    setState(() => _showMovements = !_showMovements);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: _gold,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.budgetMovementHistory,
                            style: const TextStyle(
                              color: _cream,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          _showMovements
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: _gold,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showMovements) ...[
                  const SizedBox(height: 12),
                  if (movements.isEmpty)
                    Text(
                      l10n.budgetNoMovements,
                      style: const TextStyle(color: _muted),
                    ),
                  for (final movement in movements) ...[
                    Text(
                      '${_person(movement.debtor, names)} → '
                      '${_person(movement.creditor, names)}',
                      style: const TextStyle(
                        color: _cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movement.expenseTitle,
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            statusText(movement.status),
                            style: const TextStyle(color: _muted),
                          ),
                        ),
                        Text(
                          _money(movement.amount, movement.currency),
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF49342B), height: 22),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
