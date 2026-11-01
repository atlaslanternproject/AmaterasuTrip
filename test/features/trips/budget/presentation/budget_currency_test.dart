import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_currency.dart';

void main() {
  test('JPT legacy becomes JPY', () {
    expect(BudgetCurrency.normalize('JPT - yen giapponese'), 'JPY');
  });

  test('canonical currencies are valid', () {
    expect(BudgetCurrency.normalize('JPY'), 'JPY');
    expect(BudgetCurrency.normalize('EUR'), 'EUR');
    expect(BudgetCurrency.normalize('USD'), 'USD');
  });

  test('unsupported currency is rejected', () {
    expect(() => BudgetCurrency.normalize('XYZ'), throwsFormatException);
  });

  test('currency precision is correct', () {
    expect(BudgetCurrency.decimals('JPY'), 0);
    expect(BudgetCurrency.decimals('EUR'), 2);
  });
}
