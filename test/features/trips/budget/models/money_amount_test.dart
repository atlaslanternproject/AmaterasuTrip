import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';

void main() {
  test('amount stores minor units without floating point', () {
    final amount = MoneyAmount(currency: 'EUR', minorUnits: 1234);
    expect(amount.minorUnits, 1234);
  });

  test('same currency amounts can be added', () {
    final a = MoneyAmount(currency: 'EUR', minorUnits: 100);
    final b = MoneyAmount(currency: 'EUR', minorUnits: 250);
    expect((a + b).minorUnits, 350);
  });

  test('different currencies cannot be added', () {
    final a = MoneyAmount(currency: 'EUR', minorUnits: 100);
    final b = MoneyAmount(currency: 'JPY', minorUnits: 100);
    expect(() => a + b, throwsArgumentError);
  });

  test('unsafe integer values are rejected', () {
    expect(
      () => MoneyAmount(currency: 'EUR', minorUnits: 9007199254740992),
      throwsRangeError,
    );
  });
}
