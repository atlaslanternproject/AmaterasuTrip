// Test automatici di currency_rounding (trips/budget/calculations).
// Casi, ad esempio: "half rounds away from zero", "exact division remains exact".

import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/currency_rounding.dart';

void main() {
  test('half rounds away from zero', () {
    expect(CurrencyRounding.divide(BigInt.from(5), BigInt.two), BigInt.from(3));
    expect(
      CurrencyRounding.divide(BigInt.from(-5), BigInt.two),
      BigInt.from(-3),
    );
  });

  test('exact division remains exact', () {
    expect(
      CurrencyRounding.divide(BigInt.from(20), BigInt.from(4)),
      BigInt.from(5),
    );
  });

  test('zero denominator is rejected', () {
    expect(
      () => CurrencyRounding.divide(BigInt.one, BigInt.zero),
      throwsArgumentError,
    );
  });
}
