import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_expense_split_preview.dart';

void main() {
  test('equal shares preserve every minor unit', () {
    final shares = BudgetExpenseSplitPreview.calculate(
      totalMinor: 10000,
      participants: ['b', 'c', 'a'],
    );

    expect(shares, {'a': 3334, 'b': 3333, 'c': 3333});
  });

  test('zero custom share is allowed', () {
    final shares = BudgetExpenseSplitPreview.calculate(
      totalMinor: 10000,
      participants: ['a', 'b'],
      customShares: {'a': 10000, 'b': 0},
    );

    expect(shares['b'], 0);
  });

  test('custom shares must sum to total', () {
    expect(
      () => BudgetExpenseSplitPreview.calculate(
        totalMinor: 10000,
        participants: ['a', 'b'],
        customShares: {'a': 3000, 'b': 6000},
      ),
      throwsFormatException,
    );
  });

  test('duplicate participants are rejected', () {
    expect(
      () => BudgetExpenseSplitPreview.calculate(
        totalMinor: 100,
        participants: ['a', 'a'],
      ),
      throwsFormatException,
    );
  });

  test('empty participants are rejected', () {
    expect(
      () => BudgetExpenseSplitPreview.calculate(
        totalMinor: 100,
        participants: [],
      ),
      throwsFormatException,
    );
  });

  test('JPY distribution uses integer units', () {
    final shares = BudgetExpenseSplitPreview.calculate(
      totalMinor: 1001,
      participants: ['a', 'b'],
    );

    expect(shares, {'a': 501, 'b': 500});
  });
}
