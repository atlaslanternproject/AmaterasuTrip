import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';

void main() {
  test('EUR uses two decimal places', () {
    expect(BudgetMoneyFormatter.format(12345, 'EUR'), '123,45 EUR');
  });

  test('JPY uses no decimal places', () {
    expect(BudgetMoneyFormatter.format(12345, 'JPY'), '12345 JPY');
  });

  test('KWD uses three decimal places', () {
    expect(BudgetMoneyFormatter.format(12345, 'KWD'), '12,345 KWD');
  });

  test('negative values and zero', () {
    expect(BudgetMoneyFormatter.format(-125, 'EUR'), '-1,25 EUR');
    expect(BudgetMoneyFormatter.format(0, 'JPY'), '0 JPY');
  });

  test('dot separator preserves existing presentation', () {
    expect(
      BudgetMoneyFormatter.format(125, 'EUR', decimalSeparator: '.'),
      '1.25 EUR',
    );
  });

  test('editable amount excludes currency', () {
    expect(
      BudgetMoneyFormatter.format(125, 'EUR', includeCurrency: false),
      '1,25',
    );
  });

  test('negative editable amount', () {
    expect(
      BudgetMoneyFormatter.format(-125, 'EUR', includeCurrency: false),
      '-1,25',
    );
  });

  test('unsupported currency fails explicitly', () {
    expect(() => BudgetMoneyFormatter.format(100, 'XYZ'), throwsArgumentError);
  });

  test('unsupported separator fails explicitly', () {
    expect(
      () => BudgetMoneyFormatter.format(100, 'EUR', decimalSeparator: ';'),
      throwsArgumentError,
    );
  });
}
