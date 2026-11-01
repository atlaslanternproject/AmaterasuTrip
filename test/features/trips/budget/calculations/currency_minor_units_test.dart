import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/currency_minor_units.dart';

void main() {
  test('EUR has two decimal places', () {
    expect(CurrencyMinorUnits.decimals('EUR'), 2);
    expect(CurrencyMinorUnits.factor('EUR'), 100);
  });

  test('JPY has zero decimal places', () {
    expect(CurrencyMinorUnits.decimals('JPY'), 0);
    expect(CurrencyMinorUnits.factor('JPY'), 1);
  });

  test('KWD has three decimal places', () {
    expect(CurrencyMinorUnits.decimals('KWD'), 3);
    expect(CurrencyMinorUnits.factor('KWD'), 1000);
  });

  test('unsupported currency is rejected', () {
    expect(() => CurrencyMinorUnits.decimals('XYZ'), throwsArgumentError);
  });
}
