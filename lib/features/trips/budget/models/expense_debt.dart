import 'money_amount.dart';

/// An obligation between two travelers for one specific expense.
class ExpenseDebt {
  const ExpenseDebt({
    required this.expenseId,
    required this.debtorUid,
    required this.creditorUid,
    required this.amount,
  });

  final String expenseId;
  final String debtorUid;
  final String creditorUid;
  final MoneyAmount amount;
}
