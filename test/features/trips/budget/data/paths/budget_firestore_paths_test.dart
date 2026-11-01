import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/data/paths/budget_firestore_paths.dart';

void main() {
  test('shared expense belongs to trip namespace', () {
    expect(
      BudgetFirestorePaths.sharedExpense('tripA', 'expense1'),
      'trips/tripA/budgetSharedExpenses/expense1',
    );
  });

  test('private expense includes owner identity', () {
    expect(
      BudgetFirestorePaths.privateExpense('tripA', 'anna', 'expense1'),
      'trips/tripA/budgetPrivateOwners/anna/expenses/expense1',
    );
  });

  test('shared revisions stay under original expense', () {
    expect(
      BudgetFirestorePaths.sharedRevisions('tripA', 'expense1'),
      'trips/tripA/budgetSharedExpenses/expense1/revisions',
    );
  });

  test('path injection is rejected', () {
    expect(
      () => BudgetFirestorePaths.sharedCollection('../other'),
      throwsArgumentError,
    );
  });

  test('empty ID is rejected', () {
    expect(
      () => BudgetFirestorePaths.sharedExpense('tripA', ''),
      throwsArgumentError,
    );
  });
}
