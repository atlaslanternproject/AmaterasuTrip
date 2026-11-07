import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../calculations/currency_minor_units.dart';
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

class _DebtRow {
  const _DebtRow(this.debtorUid, this.creditorUid, this.minorUnits);

  final String debtorUid;
  final String creditorUid;
  final int minorUnits;
}

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

  String _name(String uid, Map<String, String> names) =>
      names[uid] ?? (_it ? 'Viaggiatore' : 'Traveler');

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  int _minor(dynamic money) {
    final map = _map(money);
    final value = map['minorUnits'];
    return value is int ? value : 0;
  }

  List<_DebtRow> _buildDebts(Map<String, dynamic> snapshot) {
    if (snapshot['status'] != 'paid') {
      return [];
    }

    final shares = _map(snapshot['shares']);
    final advances = _map(snapshot['advances']);

    final uids = {...shares.keys, ...advances.keys}.toList()..sort();
    final debtors = <String, int>{};
    final creditors = <String, int>{};

    for (final uid in uids) {
      final net = _minor(advances[uid]) - _minor(shares[uid]);

      if (net < 0) {
        debtors[uid] = -net;
      } else if (net > 0) {
        creditors[uid] = net;
      }
    }

    final rows = <_DebtRow>[];

    for (final debtorUid in debtors.keys) {
      var remaining = debtors[debtorUid]!;

      for (final creditorUid in creditors.keys) {
        final available = creditors[creditorUid]!;
        final amount = math.min(remaining, available);

        if (amount <= 0) {
          continue;
        }

        rows.add(_DebtRow(debtorUid, creditorUid, amount));
        remaining -= amount;
        creditors[creditorUid] = available - amount;
      }

      if (remaining != 0) {
        throw StateError('Debt allocation mismatch.');
      }
    }

    return rows;
  }

  int _sumStatus(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String debtorUid,
    String creditorUid,
    Set<String> statuses,
  ) {
    var sum = 0;

    for (final doc in docs) {
      final data = doc.data();
      if (data['debtorUid'] == debtorUid &&
          data['creditorUid'] == creditorUid &&
          statuses.contains(data['status']) &&
          data['minorUnits'] is int) {
        sum += data['minorUnits'] as int;
      }
    }

    return sum;
  }

  int? _parseAmount(String text, String currency) {
    final cleaned = text.trim().replaceAll(',', '.');
    final decimals = CurrencyMinorUnits.decimals(currency);
    final factor = CurrencyMinorUnits.factor(currency);

    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) {
      return null;
    }

    final parts = cleaned.split('.');
    if (parts.length == 2 && parts[1].length > decimals) {
      return null;
    }

    final whole = int.tryParse(parts.first);
    final fraction = parts.length == 2
        ? int.tryParse(parts.last.padRight(decimals, '0'))
        : 0;

    if (whole == null || fraction == null) {
      return null;
    }

    return whole * factor + fraction;
  }

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
    final controller = TextEditingController();

    try {
      final selected = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_it ? 'Segnala rimborso' : 'Report reimbursement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _it
                      ? 'Stai segnalando un rimborso verso $creditorName.'
                      : 'You are reporting a reimbursement to $creditorName.',
                ),
                const SizedBox(height: 8),
                Text(_it ? 'Importo massimo' : 'Maximum amount'),
                const SizedBox(height: 4),
                BudgetDisplayAmount(
                  minorUnits: maximumMinorUnits,
                  originalCurrency: currency,
                  displayCurrency: widget.displayCurrency,
                  fontSize: 16,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _it ? 'Importo rimborsato' : 'Reimbursed amount',
                    suffixText: currency,
                    helperText: _it
                        ? 'Il destinatario dovrà confermare.'
                        : 'The recipient must confirm it.',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_it ? 'Annulla' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final minor = _parseAmount(controller.text, currency);

                  if (minor == null ||
                      minor <= 0 ||
                      minor > maximumMinorUnits) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          _it ? 'Importo non valido.' : 'Invalid amount.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, minor);
                },
                child: Text(_it ? 'Invia' : 'Submit'),
              ),
            ],
          );
        },
      );

      if (selected == null) {
        return;
      }

      await _run(() async {
        final refundId = FirebaseFirestore.instance
            .collection('trips')
            .doc()
            .id;

        await _functions.httpsCallable('requestBudgetReimbursement').call({
          'tripId': widget.api.tripId,
          'expenseId': widget.expenseId,
          'refundId': refundId,
          'creditorUid': debt.creditorUid,
          'minorUnits': selected,
        });
      });
    } finally {
      controller.dispose();
    }
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
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 16,
                              ),
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
                              minorUnits: remaining,
                              originalCurrency: currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 17,
                            ),
                            if (confirmed > 0) ...[
                              const SizedBox(height: 8),
                              Text(_it ? 'Confermato' : 'Confirmed'),
                              BudgetDisplayAmount(
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
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
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
