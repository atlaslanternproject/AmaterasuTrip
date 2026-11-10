import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'budget_api.dart';
import 'budget_display_amount.dart';
import '../calculations/budget_snapshot_debts.dart';

class BudgetUserSettlementSummary extends StatefulWidget {
  const BudgetUserSettlementSummary({
    super.key,
    required this.api,
    required this.displayCurrency,
  });

  final BudgetApi api;
  final String displayCurrency;

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
    required this.expense,
  });

  final String debtor;
  final String creditor;
  final int amount;
  final String currency;
  final String status;
  final DateTime? date;
  final String expenseTitle;
  final Map<String, dynamic> expense;
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

  List<_DebtLine> _debts(Map<String, dynamic> snapshot) => [
    for (final debt in BudgetSnapshotDebts.allocate(snapshot))
      _DebtLine(debt.debtorUid, debt.creditorUid, debt.minorUnits),
  ];

  String _person(String uid, Map<String, String> names) {
    return names[uid] ?? uid;
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
                expense: data,
                expenseTitle: data['title']?.toString() ?? '',
              ),
            );
          }

          for (final debt in _debts(snapshot)) {
            final confirmed = BudgetSnapshotDebts.sumFor(
              refunds,
              debt.debtor,
              debt.creditor,
              BudgetSnapshotDebts.settledStatuses,
            );
            final pending = BudgetSnapshotDebts.sumFor(
              refunds,
              debt.debtor,
              debt.creditor,
              const {'pending'},
            );

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
          Map<String, Map<String, int>> pending, {
          required IconData icon,
          required bool incomingBalance,
        }) {
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

          final accent = incomingBalance
              ? const Color(0xFFE3A66C)
              : const Color(0xFFE17A43);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF30231E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF543A2E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF442D23),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: accent, size: 21),
                    ),
                    const SizedBox(width: 11),
                    Expanded(child: _heading(title)),
                    Text(
                      '${rows.length}',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emptyText,
                            style: const TextStyle(color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final row in rows) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _person(row.person, names),
                                style: const TextStyle(
                                  color: _cream,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: BudgetDisplayAmount(
                                minorUnits: row.value,
                                originalCurrency: row.currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        if ((pending[row.currency]?[row.person] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.budgetPendingConfirmation,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                BudgetDisplayAmount(
                                  minorUnits:
                                      pending[row.currency]![row.person]!,
                                  originalCurrency: row.currency,
                                  displayCurrency: widget.displayCurrency,
                                  fontSize: 13,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF49342B), height: 1),
                ],
              ],
            ),
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
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF49352A)),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 680;
                    final cardWidth = wide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: balanceGroup(
                            l10n.budgetOthersOweYou,
                            l10n.budgetNothingToReceive,
                            incoming,
                            incomingPending,
                            icon: Icons.south_west_rounded,
                            incomingBalance: true,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: balanceGroup(
                            l10n.budgetYouOwe,
                            l10n.budgetNothingToPay,
                            outgoing,
                            outgoingPending,
                            icon: Icons.north_east_rounded,
                            incomingBalance: false,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(color: Color(0xFF49342B), height: 30),
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
                        Flexible(
                          child: BudgetDisplayAmount(
                            expense: movement.expense,
                            minorUnits: movement.amount,
                            originalCurrency: movement.currency,
                            displayCurrency: widget.displayCurrency,
                            fontSize: 14,
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
