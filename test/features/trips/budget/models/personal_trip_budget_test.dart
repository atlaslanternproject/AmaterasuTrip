import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/personal_trip_budget.dart';

void main() {
  test('valid personal budget', () {
    const budget = PersonalTripBudget(amountMinor: 300000, currency: 'EUR');

    expect(budget.isValid, isTrue);
    expect(budget.remainingMinor(245000), 55000);
    expect(budget.isExceeded(245000), isFalse);
  });

  test('exceeding budget never blocks calculations', () {
    const budget = PersonalTripBudget(amountMinor: 300000, currency: 'EUR');

    expect(budget.remainingMinor(335000), -35000);
    expect(budget.isExceeded(335000), isTrue);
    expect(budget.exceededMinor(335000), 35000);
  });

  test('invalid values are rejected', () {
    expect(
      PersonalTripBudget.fromMap({'amountMinor': -100, 'currency': 'EUR'}),
      isNull,
    );

    expect(
      PersonalTripBudget.fromMap({'amountMinor': 100, 'currency': 'INVALID'}),
      isNull,
    );
  });

  test('missing budget is optional', () {
    expect(PersonalTripBudget.fromMap(null), isNull);
  });

  test('valid data round trip', () {
    const budget = PersonalTripBudget(amountMinor: 500000, currency: 'JPY');

    final restored = PersonalTripBudget.fromMap(budget.toMap());

    expect(restored?.amountMinor, 500000);
    expect(restored?.currency, 'JPY');
  });
}
