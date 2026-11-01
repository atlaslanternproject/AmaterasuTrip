import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/currency_exchange_rate.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/currency_converter.dart';

void main() {
  test('EUR converts to JPY', () {
    final amount = MoneyAmount(currency: 'EUR', minorUnits: 1000);

    final rate = CurrencyExchangeRate(
      sourceCurrency: 'EUR',
      targetCurrency: 'JPY',
      numerator: BigInt.from(160),
      denominator: BigInt.one,
      observedAt: DateTime.utc(2026, 11, 1),
      isManual: false,
    );

    final result = CurrencyConverter.convert(amount: amount, rate: rate);

    expect(result.currency, 'JPY');
    expect(result.minorUnits, 1600);
  });

  test('JPY converts to EUR with rounding', () {
    final amount = MoneyAmount(currency: 'JPY', minorUnits: 1000);

    final rate = CurrencyExchangeRate(
      sourceCurrency: 'JPY',
      targetCurrency: 'EUR',
      numerator: BigInt.one,
      denominator: BigInt.from(160),
      observedAt: DateTime.utc(2026, 11, 1),
      isManual: true,
    );

    final result = CurrencyConverter.convert(amount: amount, rate: rate);

    expect(result.minorUnits, 625);
  });
}
