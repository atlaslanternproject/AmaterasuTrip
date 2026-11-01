import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';

void main() {
  test('EUR cents are exact', () {
    expect(BudgetMoneyInput.parse('12,34', 'EUR'), 1234);
  });

  test('JPY rejects decimal amounts', () {
    expect(
      () => BudgetMoneyInput.parse('100.50', 'JPY'),
      throwsFormatException,
    );
  });

  test('zero amount is rejected', () {
    expect(() => BudgetMoneyInput.parse('0', 'EUR'), throwsFormatException);
  });

  test('three-decimal currency is supported', () {
    expect(BudgetMoneyInput.parse('1.250', 'KWD'), 1250);
  });
}
