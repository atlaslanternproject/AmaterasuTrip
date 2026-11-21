// Parte di budget_reimbursements_panel.dart: dialogo
// per richiedere un rimborso.

part of 'budget_reimbursements_panel.dart';

extension _BudgetReimbursementsPanelStateRequest on _BudgetReimbursementsPanelState {
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
              backgroundColor: AmaterasuColors.surfaceCard,
              title: Text(
                budgetL10n(_it).btRefundsReportReimbursement,
                style: const TextStyle(color: AmaterasuColors.textPrimary),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budgetL10n(_it).btRefundsReimbursementTo(creditorName)),
                      const SizedBox(height: 10),
                      Text(budgetL10n(_it).btRefundsMaximumReimbursable),
                      BudgetDisplayAmount(
                        expense: widget.expense,
                        minorUnits: maximumMinorUnits,
                        originalCurrency: currency,
                        displayCurrency: widget.displayCurrency,
                        fontSize: 17,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        budgetL10n(_it).btRefundsRecordHowYouReimbursed(currency),
                        style: const TextStyle(color: AmaterasuColors.textSecondary),
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
                        '${budgetL10n(_it).btRefundsDeclaredTotal}: '
                        '${BudgetMoneyFormatter.format(total, currency)}',
                        style: const TextStyle(
                          color: AmaterasuColors.accentGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!valid)
                        Text(
                          budgetL10n(_it).btRefundsAddValidMethodsThe,
                          style: const TextStyle(
                            color: AmaterasuColors.accentErrorSoft,
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
                  child: Text(budgetL10n(_it).btActionCancel),
                ),
                FilledButton(
                  onPressed: valid
                      ? () => Navigator.pop(
                          dialogContext,
                          List<BudgetPaymentAllocation>.of(allocations),
                        )
                      : null,
                  child: Text(budgetL10n(_it).btRefundsSubmitRequest),
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
}
