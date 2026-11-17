import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_day.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 3, 9, 18, 45);
  final createdAt = Timestamp.fromDate(created);

  test('uses expenseDate as a local calendar day', () {
    final day = budgetExpenseDay({
      'expenseDate': '2024-02-29',
      'createdAt': createdAt,
    });
    expect(day, DateTime(2024, 2, 29));
    expect(day!.hour, 0);
  });

  test('expenseDate wins over createdAt', () {
    expect(
      budgetExpenseDay({'expenseDate': '2026-01-02', 'createdAt': createdAt}),
      DateTime(2026, 1, 2),
    );
  });

  test('tolerates surrounding spaces', () {
    expect(
      budgetExpenseDay({'expenseDate': ' 2026-01-02 '}),
      DateTime(2026, 1, 2),
    );
  });

  test('old records without expenseDate use createdAt', () {
    expect(budgetExpenseDay({'createdAt': createdAt}), created);
  });

  test('null expenseDate uses createdAt', () {
    expect(
      budgetExpenseDay({'expenseDate': null, 'createdAt': createdAt}),
      created,
    );
  });

  for (final strange in <Object>[
    '',
    'yesterday',
    '03/11/2026',
    '2026-1-2',
    '2026-02-30',
    '2025-02-29',
    '2026-13-01',
    '2026-00-10',
    '2026-11-03T10:00:00Z',
    20261103,
    true,
  ]) {
    test('strange expenseDate "$strange" falls back to createdAt', () {
      expect(
        budgetExpenseDay({'expenseDate': strange, 'createdAt': createdAt}),
        created,
      );
    });
  }

  test('no usable date returns null instead of inventing one', () {
    expect(budgetExpenseDay({}), isNull);
    expect(budgetExpenseDay({'expenseDate': 'nope'}), isNull);
    expect(budgetExpenseDay({'createdAt': '2026-01-01'}), isNull);
  });
}
