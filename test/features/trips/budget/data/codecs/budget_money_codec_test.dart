import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/data/codecs/budget_money_codec.dart';

void main() {
  test('money round-trip preserves exact cents', () {
    final original = MoneyAmount(currency: 'EUR', minorUnits: 12345);
    final restored = BudgetMoneyCodec.decode(BudgetMoneyCodec.encode(original));
    expect(restored, original);
  });

  test('JPY round-trip preserves integer amount', () {
    final original = MoneyAmount(currency: 'JPY', minorUnits: 15000);
    expect(
      BudgetMoneyCodec.decode(BudgetMoneyCodec.encode(original)),
      original,
    );
  });

  test('floating-point minor units are rejected', () {
    expect(
      () => BudgetMoneyCodec.decode({'currency': 'EUR', 'minorUnits': 12.5}),
      throwsFormatException,
    );
  });
}
