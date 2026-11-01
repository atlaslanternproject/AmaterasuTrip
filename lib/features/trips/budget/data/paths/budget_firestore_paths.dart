/// Firestore path construction for the Budget feature.
///
/// This class does not grant permissions or execute queries.
abstract final class BudgetFirestorePaths {
  static final RegExp _validId = RegExp(r'^[A-Za-z0-9_-]+$');

  static String _id(String value) {
    if (value.isEmpty || !_validId.hasMatch(value)) {
      throw ArgumentError.value(value, 'id', 'Invalid Firestore ID');
    }
    return value;
  }

  static String sharedCollection(String tripId) =>
      'trips/${_id(tripId)}/budgetSharedExpenses';

  static String sharedExpense(String tripId, String expenseId) =>
      '${sharedCollection(tripId)}/${_id(expenseId)}';

  static String sharedRevisions(String tripId, String expenseId) =>
      '${sharedExpense(tripId, expenseId)}/revisions';

  static String sharedProposals(String tripId, String expenseId) =>
      '${sharedExpense(tripId, expenseId)}/proposals';

  static String sharedReimbursements(String tripId, String expenseId) =>
      '${sharedExpense(tripId, expenseId)}/reimbursements';

  static String privateOwner(String tripId, String ownerUid) =>
      'trips/${_id(tripId)}/budgetPrivateOwners/${_id(ownerUid)}';

  static String privateCollection(String tripId, String ownerUid) =>
      '${privateOwner(tripId, ownerUid)}/expenses';

  static String privateExpense(
    String tripId,
    String ownerUid,
    String expenseId,
  ) => '${privateCollection(tripId, ownerUid)}/${_id(expenseId)}';
}
