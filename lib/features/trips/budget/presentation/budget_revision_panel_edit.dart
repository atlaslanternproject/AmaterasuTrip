// Parte di budget_revision_panel.dart: dialogo per proporre
// una modifica della spesa.

part of 'budget_revision_panel.dart';

extension _BudgetRevisionPanelStateEdit on _BudgetRevisionPanelState {
  // TODO(audit): metodo unico di ~252 righe: estrarre il dialogo di modifica in un widget.
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
              backgroundColor: AmaterasuColors.surfaceRaised,
              title: Text(l10n.budgetRevisionEdit),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.budgetRevisionInfo),
                      const SizedBox(height: AmaterasuSpacing.md),
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
                      const SizedBox(height: AmaterasuSpacing.sm),
                      for (final payer in payerControllers.entries) ...[
                        TextField(
                          controller: payer.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${names[payer.key] ?? BudgetPeople.recorded(widget.expense)[payer.key] ?? l10n.b86FormerTraveler} ($currency)',
                          ),
                        ),
                        const SizedBox(height: AmaterasuSpacing.sm),
                      ],
                      Text(
                        l10n.budgetMultiPayerApproval,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AmaterasuColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.budgetRevisionShares,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AmaterasuSpacing.sm),
                      for (final share in shareControllers.entries) ...[
                        TextField(
                          controller: share.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${names[share.key] ?? BudgetPeople.recorded(widget.expense)[share.key] ?? l10n.b86FormerTraveler} ($currency)',
                          ),
                        ),
                        const SizedBox(height: AmaterasuSpacing.sm),
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
}
