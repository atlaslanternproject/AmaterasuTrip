import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_filters.dart';

Map<String, dynamic> expense(int amount, String currency, DateTime date) {
  return {
    'createdAt': Timestamp.fromDate(date),
    'snapshot': {
      'status': 'paid',
      'total': {'minorUnits': amount, 'currency': currency},
    },
  };
}

void main() {
  final older = DateTime(2026, 1, 1);
  final newer = DateTime(2026, 2, 1);

  test('newest sorts descending by recording date', () {
    final a = expense(100, 'EUR', older);
    final b = expense(200, 'EUR', newer);

    expect(const BudgetExpenseFilters().compare(a, b), greaterThan(0));
  });

  test('oldest sorts ascending by recording date', () {
    final a = expense(100, 'EUR', older);
    final b = expense(200, 'EUR', newer);

    expect(
      const BudgetExpenseFilters(sort: 'oldest').compare(a, b),
      lessThan(0),
    );
  });

  test('ascending amount compares within the same currency', () {
    final a = expense(100, 'EUR', newer);
    final b = expense(200, 'EUR', older);

    expect(
      const BudgetExpenseFilters(sort: 'amount-asc').compare(a, b),
      lessThan(0),
    );
  });

  test('descending amount compares within the same currency', () {
    final a = expense(100, 'EUR', newer);
    final b = expense(200, 'EUR', older);

    expect(
      const BudgetExpenseFilters(sort: 'amount-desc').compare(a, b),
      greaterThan(0),
    );
  });

  test('different currencies group by code, not raw amount', () {
    final eur = expense(100, 'EUR', newer);
    final jpy = expense(1, 'JPY', older);

    for (final sort in ['amount-asc', 'amount-desc']) {
      final filters = BudgetExpenseFilters(sort: sort);
      expect(filters.compare(eur, jpy), lessThan(0));
      expect(filters.compare(jpy, eur), greaterThan(0));
    }
  });

  test('equal amounts use recording date as tie-breaker', () {
    final a = expense(100, 'EUR', older);
    final b = expense(100, 'EUR', newer);

    expect(
      const BudgetExpenseFilters(sort: 'amount-asc').compare(a, b),
      greaterThan(0),
    );
  });
}
