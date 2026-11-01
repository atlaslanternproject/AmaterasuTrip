import '../models/expense_financial_snapshot.dart';
import '../models/expense_payment_status.dart';
import 'custom_split_validator.dart';
import 'expense_outstanding_calculator.dart';

/// Validates financial consistency for an expense.
///
/// Approval, access control and persistence are separate concerns.
abstract final class ExpenseFinancialValidator {
  static void validate(ExpenseFinancialSnapshot expense) {
    if (expense.total.minorUnits <= 0) {
      throw ArgumentError('Expense total must be positive.');
    }

    CustomSplitValidator.validate(total: expense.total, shares: expense.shares);

    final remaining = ExpenseOutstandingCalculator.calculate(
      total: expense.total,
      advances: expense.advances,
    );

    final paid = expense.total.minorUnits - remaining.minorUnits;

    switch (expense.status) {
      case ExpensePaymentStatus.planned:
        if (paid != 0) {
          throw ArgumentError(
            'Planned expenses cannot contain actual advances.',
          );
        }
        break;

      case ExpensePaymentStatus.outstanding:
        if (remaining.minorUnits <= 0) {
          throw ArgumentError(
            'Outstanding expense must have an unpaid amount.',
          );
        }
        break;

      case ExpensePaymentStatus.paid:
        if (remaining.minorUnits != 0) {
          throw ArgumentError('Paid expense must be fully funded.');
        }
        break;
    }
  }
}
