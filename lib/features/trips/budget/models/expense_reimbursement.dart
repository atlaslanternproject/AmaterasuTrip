import 'money_amount.dart';
import 'reimbursement_status.dart';

/// Manual reimbursement declared between two travelers.
///
/// Only confirmed reimbursements affect outstanding balances.
class ExpenseReimbursement {
  const ExpenseReimbursement({
    required this.id,
    required this.expenseId,
    required this.debtorUid,
    required this.creditorUid,
    required this.amount,
    required this.status,
  });

  final String id;
  final String expenseId;
  final String debtorUid;
  final String creditorUid;
  final MoneyAmount amount;
  final ReimbursementStatus status;
}
