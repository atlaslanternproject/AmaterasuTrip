// Parte di budget_reimbursements_panel.dart: azioni sui rimborsi
// (chiusura debito, conferma, metodi di pagamento).

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_reimbursements_panel.dart';

extension _BudgetReimbursementsPanelStateActions on _BudgetReimbursementsPanelState {
  /// B8.6: the creditor closes the remaining debt of a former traveler.
  Future<void> _closeDebt(_DebtRow debt, String debtorName) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CloseDebtDialog(debtorName: debtorName),
    );
    if (reason == null || reason.length < 3) return;
    await _run(
      () => widget.api.closeFormerTravelerDebt(
        expenseId: widget.expenseId,
        debtorUid: debt.debtorUid,
        reason: reason,
      ),
    );
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
          _message = budgetL10n(_it).btRefundsOperationRecorded;
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

  String _methodLabel(BudgetPaymentMethod method) {
    switch (method) {
      case BudgetPaymentMethod.cash:
        return budgetL10n(_it).btMethodsCash;
      case BudgetPaymentMethod.card:
        return budgetL10n(_it).btMethodsCard;
      case BudgetPaymentMethod.bankTransfer:
        return budgetL10n(_it).btMethodsBankTransfer;
      case BudgetPaymentMethod.paypal:
        return 'PayPal';
      case BudgetPaymentMethod.satispay:
        return 'Satispay';
      case BudgetPaymentMethod.other:
        return budgetL10n(_it).btMethodsOther;
    }
  }

  Widget _paymentDetails(Map<String, dynamic> reimbursement, String currency) {
    final raw = reimbursement['paymentMethods'];

    if (raw is! List || raw.isEmpty) {
      return Text(
        budgetL10n(_it).btRefundsReimbursementMethodNotRecorded,
        style: const TextStyle(color: AmaterasuColors.textSecondary, fontSize: 12),
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
      return Text(budgetL10n(_it).btRefundsDetailsUnavailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          budgetL10n(_it).btRefundsDeclaredMethods,
          style: const TextStyle(color: AmaterasuColors.textSecondary, fontSize: 12),
        ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${_methodLabel(entry.method)}'
              '${entry.otherLabel == null ? "" : " (${entry.otherLabel})"}'
              ' · ${BudgetMoneyFormatter.format(entry.minorUnits, currency)}',
              style: const TextStyle(color: AmaterasuColors.textPrimary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
