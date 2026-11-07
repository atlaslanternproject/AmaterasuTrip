import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_money_input.dart';

void main() {
  group('B8.2 - expense total', () {
    test('positive EUR amount', () {
      expect(BudgetMoneyInput.parse('12,50', 'EUR'), 1250);
    });

    test('zero total is rejected', () {
      expect(() => BudgetMoneyInput.parse('0', 'EUR'), throwsFormatException);
    });

    test('negative amount is rejected', () {
      expect(() => BudgetMoneyInput.parse('-1', 'EUR'), throwsFormatException);
    });

    test('invalid decimal precision is rejected', () {
      expect(
        () => BudgetMoneyInput.parse('1,234', 'EUR'),
        throwsFormatException,
      );
    });
  });

  group('B8.2 - custom shares and revisions', () {
    test('zero share is allowed explicitly', () {
      expect(BudgetMoneyInput.parse('0', 'EUR', allowZero: true), 0);
    });

    test('positive share remains valid', () {
      expect(BudgetMoneyInput.parse('12,50', 'EUR', allowZero: true), 1250);
    });

    test('JPY accepts no fractions', () {
      expect(BudgetMoneyInput.parse('1250', 'JPY', allowZero: true), 1250);

      expect(
        () => BudgetMoneyInput.parse('12,50', 'JPY', allowZero: true),
        throwsFormatException,
      );
    });

    test('KWD uses three fraction digits', () {
      expect(BudgetMoneyInput.parse('1,234', 'KWD', allowZero: true), 1234);
    });

    test('unsafe integer amount is rejected', () {
      expect(
        () =>
            BudgetMoneyInput.parse('90071992547409,92', 'EUR', allowZero: true),
        throwsFormatException,
      );
    });

    test('unsupported currency is rejected', () {
      expect(
        () => BudgetMoneyInput.parse('1', 'XYZ', allowZero: true),
        throwsArgumentError,
      );
    });
  });
}
