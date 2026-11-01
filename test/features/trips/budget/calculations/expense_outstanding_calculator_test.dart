import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/expense_outstanding_calculator.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

void main() {
  test('no payment means full amount outstanding', () {
    final remaining = ExpenseOutstandingCalculator.calculate(
      total: eur(50000),
      advances: {},
    );

    expect(remaining.minorUnits, 50000);
  });

  test('partial hotel deposit leaves correct remainder', () {
    final remaining = ExpenseOutstandingCalculator.calculate(
      total: eur(50000),
      advances: {'luca': eur(10000)},
    );

    expect(remaining.minorUnits, 40000);
  });

  test('multiple advances reduce supplier remainder', () {
    final remaining = ExpenseOutstandingCalculator.calculate(
      total: eur(50000),
      advances: {'luca': eur(20000), 'anna': eur(15000)},
    );

    expect(remaining.minorUnits, 15000);
  });

  test('overpayment is rejected', () {
    expect(
      () => ExpenseOutstandingCalculator.calculate(
        total: eur(50000),
        advances: {'luca': eur(50001)},
      ),
      throwsArgumentError,
    );
  });
}
