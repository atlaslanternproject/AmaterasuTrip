import '../calculations/expense_debt_calculator.dart';
import '../calculations/reimbursement_remaining_calculator.dart';
import '../models/expense_revision.dart';
import '../models/expense_reimbursement.dart';
import '../models/reimbursement_status.dart';
import '../models/expense_payment_status.dart';

/// Prevents changing the meaning of confirmed reimbursements.
///
/// An already reimbursed debtor-creditor pair must retain
/// its original debt amount within the same expense.
abstract final class ExpenseReimbursementRevisionGuard {
  static void validate({
    required ExpenseRevision current,
    required ExpenseRevision proposed,
    required List<ExpenseReimbursement> reimbursements,
  }) {
    if (reimbursements.isEmpty) return;

    if (current.snapshot.status != ExpensePaymentStatus.paid) {
      throw StateError('Reimbursements require a paid source expense.');
    }

    final previousDebts = ExpenseDebtCalculator.calculate(
      expenseId: current.expenseId,
      expense: current.snapshot,
    );

    final nextDebts = proposed.snapshot.status == ExpensePaymentStatus.paid
        ? ExpenseDebtCalculator.calculate(
            expenseId: proposed.expenseId,
            expense: proposed.snapshot,
          )
        : [];

    final confirmed = reimbursements
        .where((r) => r.status == ReimbursementStatus.confirmed)
        .toList();

    for (final reimbursement in reimbursements) {
      if (reimbursement.expenseId != current.expenseId) {
        throw ArgumentError('Reimbursement belongs to another expense.');
      }
    }

    if (reimbursements.map((r) => r.id).toSet().length !=
        reimbursements.length) {
      throw ArgumentError('Duplicate reimbursement IDs.');
    }

    for (final debt in previousDebts) {
      final related = reimbursements
          .where(
            (r) =>
                r.debtorUid == debt.debtorUid &&
                r.creditorUid == debt.creditorUid,
          )
          .toList();

      ReimbursementRemainingCalculator.calculate(
        debt: debt,
        reimbursements: related,
      );
    }

    for (final reimbursement in reimbursements) {
      final matching = previousDebts.where(
        (debt) =>
            debt.debtorUid == reimbursement.debtorUid &&
            debt.creditorUid == reimbursement.creditorUid,
      );

      if (matching.length != 1) {
        throw StateError('Reimbursement has no unique original debt.');
      }
    }

    for (final reimbursement in confirmed) {
      final oldDebt = previousDebts.singleWhere(
        (debt) =>
            debt.debtorUid == reimbursement.debtorUid &&
            debt.creditorUid == reimbursement.creditorUid,
      );

      final replacements = nextDebts.where(
        (debt) =>
            debt.debtorUid == oldDebt.debtorUid &&
            debt.creditorUid == oldDebt.creditorUid &&
            debt.amount == oldDebt.amount,
      );

      if (replacements.length != 1) {
        throw StateError('Revision would alter an already reimbursed debt.');
      }
    }
  }
}
