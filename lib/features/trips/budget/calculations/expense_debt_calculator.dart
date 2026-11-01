import '../models/expense_debt.dart';
import '../models/expense_financial_snapshot.dart';
import '../models/expense_payment_status.dart';
import '../models/money_amount.dart';
import 'expense_financial_validator.dart';

/// Allocates net debts within one fully paid expense.
///
/// Does not combine, cancel or simplify debts across expenses.
/// For multiple payers, pairwise allocation is deterministic,
/// but does not claim to reconstruct actual payment agreements.
abstract final class ExpenseDebtCalculator {
  static List<ExpenseDebt> calculate({
    required String expenseId,
    required ExpenseFinancialSnapshot expense,
  }) {
    if (expenseId.trim().isEmpty) {
      throw ArgumentError('Expense ID cannot be empty.');
    }

    ExpenseFinancialValidator.validate(expense);

    if (expense.status != ExpensePaymentStatus.paid) {
      throw StateError('Final traveler debts require a fully paid expense.');
    }

    final allUids = <String>{
      ...expense.shares.keys,
      ...expense.advances.keys,
    }.toList()..sort();

    final debtors = <String, int>{};
    final creditors = <String, int>{};

    for (final uid in allUids) {
      final share = expense.shares[uid]?.minorUnits ?? 0;
      final advance = expense.advances[uid]?.minorUnits ?? 0;
      final net = advance - share;

      if (net < 0) {
        debtors[uid] = -net;
      } else if (net > 0) {
        creditors[uid] = net;
      }
    }

    final result = <ExpenseDebt>[];

    for (final debtor in debtors.keys) {
      var remaining = debtors[debtor]!;

      for (final creditor in creditors.keys) {
        final available = creditors[creditor]!;
        if (remaining == 0 || available == 0) {
          continue;
        }

        final allocated = remaining < available ? remaining : available;

        result.add(
          ExpenseDebt(
            expenseId: expenseId,
            debtorUid: debtor,
            creditorUid: creditor,
            amount: MoneyAmount(
              currency: expense.total.currency,
              minorUnits: allocated,
            ),
          ),
        );

        remaining -= allocated;
        creditors[creditor] = available - allocated;
      }

      if (remaining != 0) {
        throw StateError('Debt allocation is not balanced.');
      }
    }

    if (creditors.values.any((value) => value != 0)) {
      throw StateError('Unallocated creditor balance.');
    }

    return List.unmodifiable(result);
  }
}
