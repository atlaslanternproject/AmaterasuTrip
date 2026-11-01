import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/custom_split_validator.dart';

void main() {
  test('valid custom shares are accepted', () {
    expect(
      () => CustomSplitValidator.validate(
        total: MoneyAmount(currency: 'EUR', minorUnits: 10000),
        shares: {
          'a': MoneyAmount(currency: 'EUR', minorUnits: 7000),
          'b': MoneyAmount(currency: 'EUR', minorUnits: 3000),
        },
      ),
      returnsNormally,
    );
  });

  test('incorrect shares are rejected', () {
    expect(
      () => CustomSplitValidator.validate(
        total: MoneyAmount(currency: 'EUR', minorUnits: 10000),
        shares: {
          'a': MoneyAmount(currency: 'EUR', minorUnits: 6000),
          'b': MoneyAmount(currency: 'EUR', minorUnits: 3000),
        },
      ),
      throwsArgumentError,
    );
  });
}
