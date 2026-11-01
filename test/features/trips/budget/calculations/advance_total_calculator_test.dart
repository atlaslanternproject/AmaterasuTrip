import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/advance_total_calculator.dart';

void main() {
  test('multiple advances are summed', () {
    final total = AdvanceTotalCalculator.sum(
      currency: 'EUR',
      advances: {
        'a': MoneyAmount(currency: 'EUR', minorUnits: 6000),
        'b': MoneyAmount(currency: 'EUR', minorUnits: 4000),
      },
    );

    expect(total.minorUnits, 10000);
  });

  test('partial advances are allowed', () {
    final paid = AdvanceTotalCalculator.sum(
      currency: 'EUR',
      advances: {'a': MoneyAmount(currency: 'EUR', minorUnits: 10000)},
    );

    expect(paid.minorUnits, 10000);
  });

  test('negative advances are rejected', () {
    expect(
      () => AdvanceTotalCalculator.sum(
        currency: 'EUR',
        advances: {'a': MoneyAmount(currency: 'EUR', minorUnits: -100)},
      ),
      throwsArgumentError,
    );
  });
}
