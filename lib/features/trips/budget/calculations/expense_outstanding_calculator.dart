import '../models/money_amount.dart';
import 'advance_total_calculator.dart';

/// Returns the remaining amount payable to the supplier.
///
/// This does not calculate reimbursements between travelers.
abstract final class ExpenseOutstandingCalculator {
  static MoneyAmount calculate({
    required MoneyAmount total,
    required Map<String, MoneyAmount> advances,
  }) {
    if (total.minorUnits <= 0) {
      throw ArgumentError('Expense total must be positive.');
    }

    if (advances.isEmpty) {
      return MoneyAmount(
        currency: total.currency,
        minorUnits: total.minorUnits,
      );
    }

    final paid = AdvanceTotalCalculator.sum(
      currency: total.currency,
      advances: advances,
    );

    if (paid.minorUnits > total.minorUnits) {
      throw ArgumentError('Advances exceed expense total.');
    }

    return total - paid;
  }
}
