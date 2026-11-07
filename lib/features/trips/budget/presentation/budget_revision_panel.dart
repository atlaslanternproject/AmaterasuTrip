import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/currency_minor_units.dart';
import 'budget_api.dart';

class BudgetRevisionPanel extends StatefulWidget {
  const BudgetRevisionPanel({
    super.key,
    required this.api,
    required this.expenseId,
    required this.expense,
  });

  final BudgetApi api;
  final String expenseId;
  final Map<String, dynamic> expense;

  @override
  State<BudgetRevisionPanel> createState() => _BudgetRevisionPanelState();
}

class _BudgetRevisionPanelState extends State<BudgetRevisionPanel> {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  bool _busy = false;
  String? _feedback;
  late Future<Map<String, String>> _names;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _proposals =
      FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.api.tripId)
          .collection('budgetSharedExpenses')
          .doc(widget.expenseId)
          .collection('proposals')
          .snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reimbursements =
      FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.api.tripId)
          .collection('budgetSharedExpenses')
          .doc(widget.expenseId)
          .collection('reimbursements')
          .snapshots();

  @override
  void initState() {
    super.initState();
    _names = widget.api.travelerNameMap;
  }

  Map<String, dynamic> _map(dynamic raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  int _units(dynamic raw) {
    final value = _map(raw)['minorUnits'];
    return value is int ? value : 0;
  }

  String _formatted(int minor, String currency) {
    return BudgetMoneyFormatter.format(
      minor,
      currency,
      decimalSeparator: '.',
      includeCurrency: false,
    );
  }

  int? _parse(String text, String currency) {
    final value = text.trim().replaceAll(',', '.');
    final decimals = CurrencyMinorUnits.decimals(currency);
    final factor = CurrencyMinorUnits.factor(currency);

    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');

    if (parts.length == 2 && parts[1].length > decimals) {
      return null;
    }

    final major = int.tryParse(parts.first);
    final fractional = parts.length == 2
        ? int.tryParse(parts.last.padRight(decimals, '0'))
        : 0;

    if (major == null || fractional == null) {
      return null;
    }

    final result = major * factor + fractional;

    if (result < 0 || result > 9007199254740991) {
      return null;
    }

    return result;
  }

  Future<void> _call(String name, Map<String, dynamic> payload) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _feedback = null;
    });

    try {
      await _functions.httpsCallable(name).call(payload);

      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = AppLocalizations.of(context)!.budgetRevisionSent;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = '${error.code}: ${error.message ?? ''}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _edit(Map<String, String> names) async {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _map(widget.expense['snapshot']);
    final total = _map(snapshot['total']);
    final shares = _map(snapshot['shares']);
    final advances = _map(snapshot['advances']);
    final currency = total['currency']?.toString() ?? 'EUR';

    final amountController = TextEditingController(
      text: _formatted(_units(total), currency),
    );
    final shareControllers = <String, TextEditingController>{};
    final payerControllers = <String, TextEditingController>{};
    final people = <String>{...shares.keys, ...advances.keys}.toList()..sort();

    for (final uid in shares.keys) {
      shareControllers[uid] = TextEditingController(
        text: _formatted(_units(shares[uid]), currency),
      );
    }
    for (final uid in people) {
      payerControllers[uid] = TextEditingController(
        text: _formatted(_units(advances[uid]), currency),
      );
    }

    // Wait for the dialog transition to complete before disposing controllers.
    ModalRoute<dynamic>? dialogRoute;
    var status = snapshot['status']?.toString() ?? 'planned';
    try {
      final proposed = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          dialogRoute ??= ModalRoute.of(dialogContext);
          return StatefulBuilder(
            builder: (dialogContext, refresh) => AlertDialog(
              backgroundColor: const Color(0xFF241A16),
              title: Text(l10n.budgetRevisionEdit),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.budgetRevisionInfo),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (text) {
                          final units = _parse(text, currency);
                          if (units == null ||
                              units <= 0 ||
                              shareControllers.isEmpty) {
                            return;
                          }
                          final keys = shareControllers.keys.toList()..sort();
                          final basic = units ~/ keys.length;
                          final remainder = units % keys.length;
                          for (var i = 0; i < keys.length; i++) {
                            final share = basic + (i < remainder ? 1 : 0);
                            final field = shareControllers[keys[i]]!;
                            final value = _formatted(share, currency);
                            field.value = TextEditingValue(
                              text: value,
                              selection: TextSelection.collapsed(
                                offset: value.length,
                              ),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          labelText: '${l10n.budgetRevisionTotal} ($currency)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: InputDecoration(
                          labelText: l10n.budgetRevisionPaymentStatus,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'planned',
                            child: Text(l10n.budgetRevisionPlanned),
                          ),
                          DropdownMenuItem(
                            value: 'outstanding',
                            child: Text(l10n.budgetRevisionOutstanding),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text(l10n.budgetRevisionPaid),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) refresh(() => status = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.budgetMultiPayerHeading,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final payer in payerControllers.entries) ...[
                        TextField(
                          controller: payer.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${names[payer.key] ?? l10n.budgetRevisionTraveler} ($currency)',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        l10n.budgetMultiPayerApproval,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB7A99B),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.budgetRevisionShares,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final share in shareControllers.entries) ...[
                        TextField(
                          controller: share.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${names[share.key] ?? l10n.budgetRevisionTraveler} ($currency)',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.budgetRevisionCancel),
                ),
                FilledButton(
                  onPressed: () {
                    final totalMinor = _parse(amountController.text, currency);
                    if (totalMinor == null || totalMinor <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.budgetRevisionInvalid)),
                      );
                      return;
                    }
                    final nextShares = <String, dynamic>{};
                    final nextAdvances = <String, dynamic>{};
                    var sharesSum = 0;
                    var advancesSum = 0;
                    var invalid = false;

                    for (final entry in shareControllers.entries) {
                      final units = _parse(entry.value.text, currency);
                      if (units == null || units > totalMinor) {
                        invalid = true;
                        break;
                      }
                      sharesSum += units;
                      nextShares[entry.key] = {
                        'currency': currency,
                        'minorUnits': units,
                      };
                    }
                    for (final entry in payerControllers.entries) {
                      final units = _parse(entry.value.text, currency);
                      if (units == null || units > totalMinor) {
                        invalid = true;
                        break;
                      }
                      advancesSum += units;
                      if (units > 0) {
                        nextAdvances[entry.key] = {
                          'currency': currency,
                          'minorUnits': units,
                        };
                      }
                    }
                    final validStatus = switch (status) {
                      'planned' => advancesSum == 0,
                      'outstanding' => advancesSum < totalMinor,
                      'paid' => advancesSum == totalMinor,
                      _ => false,
                    };
                    if (invalid ||
                        sharesSum != totalMinor ||
                        advancesSum > totalMinor ||
                        !validStatus) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.budgetRevisionInvalid)),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, <String, dynamic>{
                      'total': {'currency': currency, 'minorUnits': totalMinor},
                      'status': status,
                      'shares': nextShares,
                      'advances': nextAdvances,
                    });
                  },
                  child: Text(l10n.budgetRevisionPropose),
                ),
              ],
            ),
          );
        },
      );
      if (proposed == null) {
        return;
      }
      final proposalId = FirebaseFirestore.instance
          .collection('trips')
          .doc()
          .id;
      await _call('proposeBudgetRevision', {
        'tripId': widget.api.tripId,
        'expenseId': widget.expenseId,
        'proposalId': proposalId,
        'snapshot': proposed,
      });
    } finally {
      // showDialog resolves on pop, before the reverse transition ends.
      // Disposing before Route.completed causes use-after-dispose on Flutter Web.
      await dialogRoute?.completed;
      amountController.dispose();
      for (final controller in shareControllers.values) {
        controller.dispose();
      }
      for (final controller in payerControllers.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _decide(String proposalId, bool approved) async {
    await _call('approveBudgetRevision', {
      'tripId': widget.api.tripId,
      'expenseId': widget.expenseId,
      'proposalId': proposalId,
      'approved': approved,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.expense['lifecycle'] == 'cancelled') {
      return const SizedBox.shrink();
    }

    final creator = widget.expense['createdByUid']?.toString();

    final canPropose = creator == widget.api.currentUid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _proposals,
      builder: (context, proposalResult) {
        if (proposalResult.hasError) {
          return Text(l10n.budgetRevisionLoadError);
        }

        if (!proposalResult.hasData) {
          return const LinearProgressIndicator();
        }

        final pending = proposalResult.data!.docs
            .where((doc) => doc.data()['state'] == 'pending')
            .toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reimbursements,
          builder: (context, reimbursementResult) {
            if (reimbursementResult.hasError) {
              return Text(l10n.budgetRevisionLoadError);
            }

            if (!reimbursementResult.hasData) {
              return const LinearProgressIndicator();
            }

            final hasReimbursements = reimbursementResult.data!.docs.isNotEmpty;

            final canEdit = canPropose && pending.isEmpty && !hasReimbursements;

            return FutureBuilder<Map<String, String>>(
              future: _names,
              builder: (context, namesResult) {
                if (namesResult.hasError) {
                  return Text(l10n.budgetNamesUnavailable);
                }

                if (!namesResult.hasData) {
                  return const LinearProgressIndicator();
                }

                final names = namesResult.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Divider(),
                    Text(
                      l10n.budgetRevisionSection,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (canPropose)
                      OutlinedButton.icon(
                        onPressed: canEdit && !_busy
                            ? () => _edit(names)
                            : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.budgetRevisionEdit),
                      ),

                    if (canPropose && hasReimbursements)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.budgetRevisionLocked,
                          style: const TextStyle(color: Color(0xFFB7A99B)),
                        ),
                      ),

                    for (final doc in pending) ...[
                      Builder(
                        builder: (context) {
                          final data = doc.data();

                          final required = List<String>.from(
                            data['requiredUids'] as List? ?? [],
                          );

                          final approved = List<String>.from(
                            data['approvedUids'] as List? ?? [],
                          );

                          final currentUid = widget.api.currentUid;

                          final canVote =
                              required.contains(currentUid) &&
                              !approved.contains(currentUid);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.budgetRevisionPending,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${approved.length}/${required.length}'),
                              const SizedBox(height: 6),
                              for (final person in required)
                                Text(
                                  '${names[person] ?? l10n.budgetRevisionTraveler}: '
                                  '${approved.contains(person) ? l10n.budgetRevisionApproved : l10n.budgetRevisionWaiting}',
                                ),
                              if (canVote)
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(doc.id, false),
                                      child: Text(l10n.budgetRevisionReject),
                                    ),
                                    FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(doc.id, true),
                                      child: Text(l10n.budgetRevisionApprove),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    ],

                    if (_busy) const LinearProgressIndicator(),

                    if (_feedback != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _feedback!,
                          style: const TextStyle(color: Color(0xFFE3A66C)),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
