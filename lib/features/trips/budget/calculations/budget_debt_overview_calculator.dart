import '../models/expense_debt.dart';
import '../models/expense_financial_snapshot.dart';
import '../models/expense_reimbursement.dart';
import 'expense_debt_calculator.dart';
import 'reimbursement_remaining_calculator.dart';

/// A single expense with its recorded reimbursements.
class BudgetDebtSource {
  const BudgetDebtSource({
    required this.expenseId,
    required this.snapshot,
    required this.reimbursements,
  });

  final String expenseId;
  final ExpenseFinancialSnapshot snapshot;
  final List<ExpenseReimbursement> reimbursements;
}

/// An original debt and its remaining, confirmed balance.
class BudgetDebtBalance {
  const BudgetDebtBalance({
    required this.debt,
    required this.remainingMinorUnits,
  });

  final ExpenseDebt debt;
  final int remainingMinorUnits;

  int get confirmedMinorUnits => debt.amount.minorUnits - remainingMinorUnits;

  bool get isSettled => remainingMinorUnits == 0;
}

/// Calculates balances by expense, without cross-expense netting.
///
/// Pending or rejected reimbursements do not reduce the balance.
/// An unpaid supplier expense cannot generate final traveler debts.
abstract final class BudgetDebtOverviewCalculator {
  static List<BudgetDebtBalance> calculate(
    Iterable<BudgetDebtSource> expenses,
  ) {
    final result = <BudgetDebtBalance>[];
    final expenseIds = <String>{};

    for (final source in expenses) {
      if (!expenseIds.add(source.expenseId)) {
        throw ArgumentError('Duplicate expense ID.');
      }

      final debts = ExpenseDebtCalculator.calculate(
        expenseId: source.expenseId,
        expense: source.snapshot,
      );

      final usedReimbursementIds = <String>{};

      for (final reimbursement in source.reimbursements) {
        if (!usedReimbursementIds.add(reimbursement.id)) {
          throw ArgumentError('Duplicate reimbursement ID.');
        }

        if (!debts.any(
          (debt) =>
              debt.debtorUid == reimbursement.debtorUid &&
              debt.creditorUid == reimbursement.creditorUid,
        )) {
          throw ArgumentError('Reimbursement does not match an expense debt.');
        }
      }

      for (final debt in debts) {
        final matching = source.reimbursements
            .where(
              (reimbursement) =>
                  reimbursement.debtorUid == debt.debtorUid &&
                  reimbursement.creditorUid == debt.creditorUid,
            )
            .toList(growable: false);

        final remaining = ReimbursementRemainingCalculator.calculate(
          debt: debt,
          reimbursements: matching,
        );

        result.add(
          BudgetDebtBalance(
            debt: debt,
            remainingMinorUnits: remaining.minorUnits,
          ),
        );
      }
    }

    return List.unmodifiable(result);
  }
}
