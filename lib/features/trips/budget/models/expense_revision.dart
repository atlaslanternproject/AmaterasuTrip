import 'expense_financial_snapshot.dart';

/// An immutable snapshot of a numbered financial revision.
///
/// Persistence and audit timestamps are separate responsibilities.
class ExpenseRevision {
  ExpenseRevision({
    required this.expenseId,
    required this.number,
    required ExpenseFinancialSnapshot snapshot,
  }) : snapshot = ExpenseFinancialSnapshot(
         total: snapshot.total,
         status: snapshot.status,
         shares: Map.unmodifiable(snapshot.shares),
         advances: Map.unmodifiable(snapshot.advances),
       ) {
    if (expenseId.trim().isEmpty || number < 1) {
      throw ArgumentError('Invalid expense revision identity.');
    }
  }

  final String expenseId;
  final int number;
  final ExpenseFinancialSnapshot snapshot;
}
