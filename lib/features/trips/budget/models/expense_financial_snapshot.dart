import 'money_amount.dart';
import 'expense_payment_status.dart';

/// Financial values for one expense at a specific point in time.
///
/// This model contains no Firestore, UI or approval logic.
class ExpenseFinancialSnapshot {
  const ExpenseFinancialSnapshot({
    required this.total,
    required this.status,
    required this.shares,
    required this.advances,
  });

  final MoneyAmount total;
  final ExpensePaymentStatus status;
  final Map<String, MoneyAmount> shares;
  final Map<String, MoneyAmount> advances;
}
