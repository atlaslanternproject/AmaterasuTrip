import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../calculations/budget_snapshot_debts.dart';
import '../models/budget_payment_allocation.dart';
import 'budget_payment_methods_editor.dart';
import 'budget_api.dart';
import 'budget_display_amount.dart';

class BudgetReimbursementsPanel extends StatefulWidget {
  const BudgetReimbursementsPanel({
    super.key,
    required this.api,
    required this.expenseId,
    required this.expense,
    required this.displayCurrency,
  });

  final BudgetApi api;
  final String expenseId;
  final Map<String, dynamic> expense;
  final String displayCurrency;

  @override
  State<BudgetReimbursementsPanel> createState() =>
      _BudgetReimbursementsPanelState();
}

typedef _DebtRow = BudgetPairDebt;

class _BudgetReimbursementsPanelState extends State<BudgetReimbursementsPanel> {
  bool _busy = false;
  String? _message;

  late final Future<Map<String, String>> _names = _loadNames();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _refunds =
      FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.api.tripId)
          .collection('budgetSharedExpenses')
          .doc(widget.expenseId)
          .collection('reimbursements')
          .snapshots();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  bool get _it => Localizations.localeOf(context).languageCode == 'it';

  Future<Map<String, String>> _loadNames() async {
    final travelers = await widget.api.travelers();
    final result = <String, String>{};

    for (final traveler in travelers) {
      final uid = traveler['uid']?.toString();
      final name = traveler['name']?.toString().trim();

      if (uid != null && name != null && name.isNotEmpty) {
        result[uid] = name;
      }
    }

    return result;
  }

  String _name(String uid, Map<String, String> names) => names[uid] ?? uid;

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  List<_DebtRow> _buildDebts(Map<String, dynamic> snapshot) =>
      BudgetSnapshotDebts.allocate(snapshot);

  int _sumStatus(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String debtorUid,
    String creditorUid,
    Set<String> statuses,
  ) => BudgetSnapshotDebts.sumFor(
    docs.map((doc) => doc.data()),
    debtorUid,
    creditorUid,
    statuses,
  );

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await action();
      if (mounted) {
        setState(() {
          _message = _it ? 'Operazione registrata.' : 'Operation recorded.';
        });
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(() {
          _message = '${error.code}: ${error.message ?? ''}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _requestReimbursement(
    _DebtRow debt,
    int maximumMinorUnits,
    String currency,
    String creditorName,
  ) async {
    final selected = await showDialog<List<BudgetPaymentAllocation>>(
      context: context,
      builder: (dialogContext) {
        List<BudgetPaymentAllocation> allocations = [];

        return StatefulBuilder(
          builder: (dialogContext, update) {
            final total = allocations.fold<int>(
              0,
              (accumulated, item) => accumulated + item.minorUnits,
            );
            final valid =
                allocations.isNotEmpty &&
                allocations.length <= 20 &&
                allocations.every(
                  (item) =>
                      item.isValid && item.payerUid == widget.api.currentUid,
                ) &&
                total > 0 &&
                total <= maximumMinorUnits;

            return AlertDialog(
              backgroundColor: const Color(0xFF231915),
              title: Text(
                _it ? 'Segnala un rimborso' : 'Report reimbursement',
                style: const TextStyle(color: Color(0xFFF2E7D5)),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _it
                            ? 'Rimborso verso $creditorName'
                            : 'Reimbursement to $creditorName',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _it ? 'Massimo rimborsabile' : 'Maximum reimbursable',
                      ),
                      BudgetDisplayAmount(
                        expense: widget.expense,
                        minorUnits: maximumMinorUnits,
                        originalCurrency: currency,
                        displayCurrency: widget.displayCurrency,
                        fontSize: 17,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _it
                            ? 'Indica come hai rimborsato in $currency. '
                                  'Il destinatario dovrà confermare.'
                            : 'Record how you reimbursed in $currency. '
                                  'The recipient must confirm.',
                        style: const TextStyle(color: Color(0xFFB7A99B)),
                      ),
                      const SizedBox(height: 12),
                      BudgetPaymentMethodsEditor(
                        currency: currency,
                        payerUid: widget.api.currentUid,
                        enabled: true,
                        onChanged: (values) {
                          update(() {
                            allocations = List<BudgetPaymentAllocation>.of(
                              values,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_it ? "Totale dichiarato" : "Declared total"}: '
                        '${BudgetMoneyFormatter.format(total, currency)}',
                        style: const TextStyle(
                          color: Color(0xFFE3A66C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!valid)
                        Text(
                          _it
                              ? 'Aggiungi metodi validi. Il totale deve '
                                    'essere positivo e non superare il massimo.'
                              : 'Add valid methods. The total must '
                                    'be positive and within the maximum.',
                          style: const TextStyle(
                            color: Color(0xFFFFA78A),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_it ? 'Annulla' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: valid
                      ? () => Navigator.pop(
                          dialogContext,
                          List<BudgetPaymentAllocation>.of(allocations),
                        )
                      : null,
                  child: Text(_it ? 'Invia richiesta' : 'Submit request'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null || selected.isEmpty) return;

    final amount = selected.fold<int>(
      0,
      (accumulated, item) => accumulated + item.minorUnits,
    );

    await _run(() async {
      final refundId = FirebaseFirestore.instance.collection('trips').doc().id;

      await _functions.httpsCallable('requestBudgetReimbursement').call({
        'tripId': widget.api.tripId,
        'expenseId': widget.expenseId,
        'refundId': refundId,
        'creditorUid': debt.creditorUid,
        'minorUnits': amount,
        'paymentMethods': selected.map((item) => item.toMap()).toList(),
      });
    });
  }

  String _methodLabel(BudgetPaymentMethod method) {
    switch (method) {
      case BudgetPaymentMethod.cash:
        return _it ? 'Contanti' : 'Cash';
      case BudgetPaymentMethod.card:
        return _it ? 'Carta' : 'Card';
      case BudgetPaymentMethod.bankTransfer:
        return _it ? 'Bonifico' : 'Bank transfer';
      case BudgetPaymentMethod.paypal:
        return 'PayPal';
      case BudgetPaymentMethod.satispay:
        return 'Satispay';
      case BudgetPaymentMethod.other:
        return _it ? 'Altro' : 'Other';
    }
  }

  Widget _paymentDetails(Map<String, dynamic> reimbursement, String currency) {
    final raw = reimbursement['paymentMethods'];

    if (raw is! List || raw.isEmpty) {
      return Text(
        _it
            ? 'Metodo di rimborso non registrato'
            : 'Reimbursement method not recorded',
        style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 12),
      );
    }

    final entries = <BudgetPaymentAllocation>[];

    for (final item in raw) {
      if (item is! Map) continue;

      final parsed = BudgetPaymentAllocation.fromMap(
        Map<String, dynamic>.from(item),
      );

      if (parsed != null) entries.add(parsed);
    }

    if (entries.isEmpty) {
      return Text(_it ? 'Dettagli non disponibili' : 'Details unavailable');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _it ? 'Metodi dichiarati' : 'Declared methods',
          style: const TextStyle(color: Color(0xFFB7A99B), fontSize: 12),
        ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${_methodLabel(entry.method)}'
              '${entry.otherLabel == null ? "" : " (${entry.otherLabel})"}'
              ' · ${BudgetMoneyFormatter.format(entry.minorUnits, currency)}',
              style: const TextStyle(color: Color(0xFFF2E7D5), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmReimbursement(String refundId, bool approved) async {
    await _run(() async {
      await _functions.httpsCallable('confirmBudgetReimbursement').call({
        'tripId': widget.api.tripId,
        'expenseId': widget.expenseId,
        'refundId': refundId,
        'approved': approved,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expense['lifecycle'] == 'cancelled') {
      return const SizedBox.shrink();
    }

    final snapshot = _map(widget.expense['snapshot']);

    if (snapshot['status'] != 'paid') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          _it
              ? 'I debiti tra viaggiatori saranno definitivi solo quando la spesa risulterà pagata al fornitore.'
              : 'Debts between travelers become final only once the supplier has been paid.',
          style: const TextStyle(color: Color(0xFFB7A99B)),
        ),
      );
    }

    final total = _map(snapshot['total']);
    final currency = total['currency']?.toString() ?? 'EUR';
    final debts = _buildDebts(snapshot);

    return FutureBuilder<Map<String, String>>(
      future: _names,
      builder: (context, namesSnapshot) {
        if (namesSnapshot.hasError) {
          return Text(
            _it
                ? 'Impossibile caricare i nomi dei viaggiatori.'
                : 'Unable to load traveler names.',
          );
        }

        if (!namesSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final names = namesSnapshot.data!;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _refunds,
          builder: (context, refundsSnapshot) {
            if (refundsSnapshot.hasError) {
              return Text(
                _it
                    ? 'Impossibile caricare i rimborsi.'
                    : 'Unable to load reimbursements.',
              );
            }

            if (!refundsSnapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final docs = refundsSnapshot.data!.docs;

            final pendingForCurrentUser = docs.where((doc) {
              final data = doc.data();
              return data['status'] == 'pending' &&
                  data['creditorUid'] == widget.api.currentUid;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Divider(),
                Text(
                  _it ? 'Debiti e rimborsi' : 'Debts and reimbursements',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _it
                      ? 'Chi deve restituire denaro può segnalare un rimborso. Chi deve riceverlo deve confermarlo.'
                      : 'Who owes money can report a reimbursement. Who should receive it must confirm it.',
                  style: const TextStyle(
                    color: Color(0xFFB7A99B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                if (pendingForCurrentUser.isNotEmpty) ...[
                  Text(
                    _it
                        ? 'Richieste in attesa della tua conferma'
                        : 'Requests waiting for your confirmation',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final doc in pendingForCurrentUser) ...[
                    Builder(
                      builder: (context) {
                        final data = doc.data();
                        final debtorUid = data['debtorUid']?.toString() ?? '';
                        final creditorUid =
                            data['creditorUid']?.toString() ?? '';
                        final minorUnits = data['minorUnits'] is int
                            ? data['minorUnits'] as int
                            : 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_name(debtorUid, names)} → ${_name(creditorUid, names)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 16,
                              ),
                              const SizedBox(height: 5),
                              for (final field in ['createdAt', 'decidedAt'])
                                if (data[field] is Timestamp)
                                  Text(
                                    '${field == "createdAt" ? (_it ? "Richiesto" : "Requested") : (_it ? "Decisione" : "Decision")} · ${MaterialLocalizations.of(context).formatMediumDate((data[field] as Timestamp).toDate())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime((data[field] as Timestamp).toDate()))}',
                                  ),
                              if (data['decidedByUid'] is String)
                                Text(
                                  '${_it ? "Deciso da" : "Decided by"} ${_name(data['decidedByUid'] as String, names)}',
                                ),
                              _paymentDetails(data, currency),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmReimbursement(
                                            doc.id,
                                            false,
                                          ),
                                    child: Text(_it ? 'Rifiuta' : 'Reject'),
                                  ),
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmReimbursement(
                                            doc.id,
                                            true,
                                          ),
                                    child: Text(_it ? 'Conferma' : 'Confirm'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const Divider(),
                ],

                for (final debt in debts) ...[
                  Builder(
                    builder: (context) {
                      final confirmed = _sumStatus(
                        docs,
                        debt.debtorUid,
                        debt.creditorUid,
                        {'confirmed'},
                      );
                      final pending = _sumStatus(
                        docs,
                        debt.debtorUid,
                        debt.creditorUid,
                        {'pending'},
                      );
                      final remaining = debt.minorUnits - confirmed;
                      final availableToDeclare = remaining - pending;
                      final isDebtor = widget.api.currentUid == debt.debtorUid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_name(debt.debtorUid, names)} → ${_name(debt.creditorUid, names)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(_it ? 'Da restituire' : 'Outstanding'),
                            const SizedBox(height: 3),
                            BudgetDisplayAmount(
                              expense: widget.expense,
                              minorUnits: remaining,
                              originalCurrency: currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 17,
                            ),
                            if (confirmed > 0) ...[
                              const SizedBox(height: 8),
                              Text(_it ? 'Confermato' : 'Confirmed'),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: confirmed,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ],
                            if (pending > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                _it
                                    ? 'In attesa di conferma'
                                    : 'Pending confirmation',
                              ),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: pending,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ],
                            if (isDebtor && availableToDeclare > 0)
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _requestReimbursement(
                                        debt,
                                        availableToDeclare,
                                        currency,
                                        _name(debt.creditorUid, names),
                                      ),
                                icon: const Icon(Icons.payments_outlined),
                                label: Text(
                                  _it
                                      ? 'Segnala un rimborso'
                                      : 'Report a reimbursement',
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (docs.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    _it ? 'Storico rimborsi' : 'Reimbursement history',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final doc in docs) ...[
                    Builder(
                      builder: (context) {
                        final data = doc.data();
                        final debtorUid = data['debtorUid']?.toString() ?? '';
                        final creditorUid =
                            data['creditorUid']?.toString() ?? '';
                        final minorUnits = data['minorUnits'] is int
                            ? data['minorUnits'] as int
                            : 0;
                        final status = data['status']?.toString() ?? 'pending';

                        String label;
                        switch (status) {
                          case 'confirmed':
                            label = _it ? 'Confermato' : 'Confirmed';
                            break;
                          case 'rejected':
                            label = _it ? 'Rifiutato' : 'Rejected';
                            break;
                          default:
                            label = _it ? 'In attesa' : 'Pending';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_name(debtorUid, names)} → ${_name(creditorUid, names)} · $label',
                                style: const TextStyle(
                                  color: Color(0xFFB7A99B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                              const SizedBox(height: 5),
                              _paymentDetails(data, currency),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],

                if (_busy) const LinearProgressIndicator(),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: Color(0xFFE3A66C)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
