import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';

void main() {
  final now = DateTime(2026, 11, 4);
  final expense = <String, dynamic>{
    'category': 'food',
    'createdAt': Timestamp.fromDate(DateTime(2026, 10, 30)),
    'snapshot': {'status': 'paid'},
  };

  test('category and status filters work together', () {
    expect(
      const BudgetExpenseFilters(
        category: 'food',
        status: 'paid',
      ).matches(expense, now),
      isTrue,
    );
    expect(
      const BudgetExpenseFilters(category: 'transport').matches(expense, now),
      isFalse,
    );
  });

  test('cancelled expenses never enter list or charts', () {
    expect(
      const BudgetExpenseFilters().matches({
        ...expense,
        'lifecycle': 'cancelled',
      }, now),
      isFalse,
    );
  });

  test('period filter uses recording time', () {
    expect(const BudgetExpenseFilters(days: 30).matches(expense, now), isTrue);
    expect(const BudgetExpenseFilters(days: 1).matches(expense, now), isFalse);
  });
}
