// Parte di budget_reimbursements_panel.dart: "Segna come pagato".
// Il creditore registra un pagamento (o conferma la richiesta in attesa
// dello stesso debitore), lo può annullare con un motivo, e lo storico
// del pannello mostra chi l'ha registrato.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_reimbursements_panel.dart';

enum _PendingChoice { confirm, another }

extension _BudgetReimbursementsPanelStateMarkPaid
    on _BudgetReimbursementsPanelState {
  /// Pending requests of the same debtor on the same debt.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pendingFor(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    _DebtRow debt,
  ) => docs.where((doc) {
    final data = doc.data();
    return data['status'] == 'pending' &&
        data['debtorUid'] == debt.debtorUid &&
        data['creditorUid'] == debt.creditorUid;
  }).toList();

  Future<void> _markAsPaid(
    _DebtRow debt,
    int remaining,
    String currency,
    String debtorName,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pending,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (pending.isNotEmpty) {
      final request = pending.first;
      final amount = request.data()['minorUnits'] is int
          ? request.data()['minorUnits'] as int
          : 0;
      final choice = await showDialog<_PendingChoice>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AmaterasuColors.surfaceCard,
          title: Text(
            l10n.btPaidPendingTitle,
            style: const TextStyle(color: AmaterasuColors.textPrimary),
          ),
          content: Text(
            l10n.btPaidPendingBody(
              debtorName,
              BudgetMoneyFormatter.format(amount, currency),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.btActionCancel),
            ),
            TextButton(
              key: const Key('paid-record-another'),
              onPressed: () =>
                  Navigator.pop(dialogContext, _PendingChoice.another),
              child: Text(l10n.btPaidRecordAnother),
            ),
            FilledButton(
              key: const Key('paid-confirm-pending'),
              onPressed: () =>
                  Navigator.pop(dialogContext, _PendingChoice.confirm),
              child: Text(l10n.btPaidConfirmPending),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == _PendingChoice.confirm) {
        await _confirmReimbursement(request.id, true);
        return;
      }
    }

    final result = await showDialog<BudgetDeclaredPaymentResult>(
      context: context,
      builder: (_) => BudgetDeclarePaymentDialog(
        debtorName: debtorName,
        remainingMinor: remaining,
        currency: currency,
      ),
    );
    if (result == null) return;

    await _run(
      () => widget.api.declarePayment(
        expenseId: widget.expenseId,
        debtorUid: debt.debtorUid,
        minorUnits: result.minorUnits,
        paidOn: result.paidOn,
        note: result.note,
        paymentMethods: result.paymentMethodsFor(debt.debtorUid),
      ),
    );
  }

  Future<void> _voidPayment(String refundId, String summary) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => BudgetVoidPaymentDialog(summary: summary),
    );
    if (reason == null || reason.length < 3) return;
    await _run(
      () => widget.api.voidPayment(
        expenseId: widget.expenseId,
        refundId: refundId,
        reason: reason,
      ),
    );
  }

  /// Details of a payment recorded by the creditor, in the panel history.
  Widget _declaredDetails(
    String refundId,
    Map<String, dynamic> data,
    Map<String, String> names,
    String currency,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const small = TextStyle(fontSize: 12);
    final recordedBy = data['recordedByUid'] ?? data['creditorUid'];
    final paidOn = DateTime.tryParse(data['paidOn']?.toString() ?? '');
    final note = data['note'];
    final isVoided = data['status'] == BudgetSnapshotDebts.voided;
    final canVoid =
        !isVoided &&
        data['status'] == 'confirmed' &&
        data['creditorUid'] == widget.api.currentUid;
    final amount = data['minorUnits'] is int ? data['minorUnits'] as int : 0;
    final debtorUid = data['debtorUid']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recordedBy is String)
          Text(l10n.btPaidRecordedBy(_name(recordedBy, names)), style: small),
        if (paidOn != null)
          Text(
            l10n.btPaidOn(MaterialLocalizations.of(context).formatMediumDate(paidOn)),
            style: small,
          ),
        if (note is String && note.trim().isNotEmpty)
          Text(l10n.btPaidNoteText(note.trim()), style: small),
        if (data['paymentMethods'] is List) _paymentDetails(data, currency),
        if (isVoided) ...[
          if (data['voidedByUid'] is String)
            Text(
              l10n.btPaidVoidedBy(_name(data['voidedByUid'] as String, names)),
              style: small,
            ),
          if (data['voidReason'] is String)
            Text(l10n.b86Reason(data['voidReason'] as String), style: small),
        ],
        if (canVoid)
          TextButton.icon(
            key: Key('paid-void-$refundId'),
            onPressed: _busy
                ? null
                : () => _voidPayment(
                    refundId,
                    '${_name(debtorUid, names)} · '
                    '${BudgetMoneyFormatter.format(amount, currency)}',
                  ),
            icon: const Icon(Icons.undo_outlined),
            label: Text(l10n.btPaidVoidAction),
          ),
      ],
    );
  }
}
