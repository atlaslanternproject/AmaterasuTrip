import 'expense_financial_snapshot.dart';

/// A proposed replacement for one exact base revision.
///
/// Creating this object never modifies an existing expense.
class ExpenseRevisionProposal {
  ExpenseRevisionProposal({
    required this.id,
    required this.expenseId,
    required this.baseRevisionNumber,
    required ExpenseFinancialSnapshot proposedSnapshot,
  }) : proposedSnapshot = ExpenseFinancialSnapshot(
         total: proposedSnapshot.total,
         status: proposedSnapshot.status,
         shares: Map.unmodifiable(proposedSnapshot.shares),
         advances: Map.unmodifiable(proposedSnapshot.advances),
       ) {
    if (id.trim().isEmpty ||
        expenseId.trim().isEmpty ||
        baseRevisionNumber < 1) {
      throw ArgumentError('Invalid revision proposal identity.');
    }
  }

  final String id;
  final String expenseId;
  final int baseRevisionNumber;
  final ExpenseFinancialSnapshot proposedSnapshot;
}
