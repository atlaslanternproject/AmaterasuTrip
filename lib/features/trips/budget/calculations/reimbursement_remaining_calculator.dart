import '../models/expense_debt.dart';
import '../models/expense_reimbursement.dart';
import '../models/reimbursement_status.dart';
import '../models/money_amount.dart';

/// Remaining amount for exactly one original debt.
///
/// Pending and rejected reimbursements do not reduce it.
abstract final class ReimbursementRemainingCalculator {
  static MoneyAmount calculate({
    required ExpenseDebt debt,
    required List<ExpenseReimbursement> reimbursements,
  }) {
    if (debt.expenseId.trim().isEmpty ||
        debt.debtorUid.trim().isEmpty ||
        debt.creditorUid.trim().isEmpty ||
        debt.debtorUid == debt.creditorUid ||
        debt.amount.minorUnits <= 0) {
      throw ArgumentError('Invalid original debt.');
    }

    var confirmed = 0;
    final ids = <String>{};

    for (final reimbursement in reimbursements) {
      if (reimbursement.id.trim().isEmpty || !ids.add(reimbursement.id)) {
        throw ArgumentError('Invalid or duplicate reimbursement ID.');
      }

      if (reimbursement.expenseId != debt.expenseId ||
          reimbursement.debtorUid != debt.debtorUid ||
          reimbursement.creditorUid != debt.creditorUid) {
        throw ArgumentError('Reimbursement does not match debt.');
      }

      if (reimbursement.amount.currency != debt.amount.currency ||
          reimbursement.amount.minorUnits <= 0) {
        throw ArgumentError('Invalid reimbursement amount.');
      }

      if (reimbursement.status == ReimbursementStatus.confirmed) {
        confirmed += reimbursement.amount.minorUnits;
      }
    }

    if (confirmed > debt.amount.minorUnits) {
      throw ArgumentError('Confirmed reimbursements exceed original debt.');
    }

    return MoneyAmount(
      currency: debt.amount.currency,
      minorUnits: debt.amount.minorUnits - confirmed,
    );
  }
}
