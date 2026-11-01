import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/equal_split_calculator.dart';

void main() {
  test('120 EUR divided among four travelers', () {
    final result = EqualSplitCalculator.split(
      amount: MoneyAmount(currency: 'EUR', minorUnits: 12000),
      participantUids: ['a', 'b', 'c', 'd'],
    );

    expect(result['a']!.minorUnits, 3000);
    expect(result['b']!.minorUnits, 3000);
    expect(result['c']!.minorUnits, 3000);
    expect(result['d']!.minorUnits, 3000);
  });

  test('remaining cents are assigned deterministically', () {
    final result = EqualSplitCalculator.split(
      amount: MoneyAmount(currency: 'EUR', minorUnits: 1000),
      participantUids: ['a', 'b', 'c'],
    );

    expect(result['a']!.minorUnits, 334);
    expect(result['b']!.minorUnits, 333);
    expect(result['c']!.minorUnits, 333);
  });

  test('duplicate participants are rejected', () {
    expect(
      () => EqualSplitCalculator.split(
        amount: MoneyAmount(currency: 'JPY', minorUnits: 100),
        participantUids: ['a', 'a'],
      ),
      throwsArgumentError,
    );
  });
}
