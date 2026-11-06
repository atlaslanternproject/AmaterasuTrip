import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/personal_budget_spending_calculator.dart';

Map<String, dynamic> example({
  String status = 'paid',
  String lifecycle = 'active',
  int share = 10000,
}) => {
  'lifecycle': lifecycle,
  'snapshot': {
    'status': status,
    'total': {'currency': 'EUR', 'minorUnits': 40000},
    'shares': {
      'atlas': {'currency': 'EUR', 'minorUnits': share},
      'yato': {'currency': 'EUR', 'minorUnits': 40000 - share},
    },
    'advances': {
      'atlas': {'currency': 'EUR', 'minorUnits': 40000},
    },
  },
};

void main() {
  test('shared paid counts only own share', () {
    final value = PersonalBudgetSpendingCalculator.ownShare(
      example(),
      uid: 'atlas',
      privateExpense: false,
    );
    expect(value?.minorUnits, 10000);
  });

  test('shared outstanding counts own share', () {
    final value = PersonalBudgetSpendingCalculator.ownShare(
      example(status: 'outstanding'),
      uid: 'atlas',
      privateExpense: false,
    );
    expect(value?.minorUnits, 10000);
  });

  test('planned is excluded', () {
    expect(
      PersonalBudgetSpendingCalculator.isIncluded(example(status: 'planned')),
      isFalse,
    );
  });

  test('cancelled is excluded', () {
    expect(
      PersonalBudgetSpendingCalculator.isIncluded(
        example(lifecycle: 'cancelled'),
      ),
      isFalse,
    );
  });

  test('private paid counts entire amount', () {
    final value = PersonalBudgetSpendingCalculator.ownShare(
      example(),
      uid: 'atlas',
      privateExpense: true,
    );
    expect(value?.minorUnits, 40000);
  });

  test('missing share is not zero', () {
    final data = example();
    final financial = data['snapshot'] as Map<String, dynamic>;
    financial['shares'] = <String, dynamic>{};

    final value = PersonalBudgetSpendingCalculator.ownShare(
      data,
      uid: 'atlas',
      privateExpense: false,
    );
    expect(value, isNull);
  });

  test('valid zero share remains zero', () {
    final value = PersonalBudgetSpendingCalculator.ownShare(
      example(share: 0),
      uid: 'atlas',
      privateExpense: false,
    );
    expect(value?.minorUnits, 0);
  });
}
