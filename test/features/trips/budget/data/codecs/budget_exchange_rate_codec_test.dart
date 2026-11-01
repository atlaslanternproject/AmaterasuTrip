import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/currency_exchange_rate.dart';
import 'package:amaterasutrip/features/trips/budget/data/codecs/budget_exchange_rate_codec.dart';

void main() {
  test('rational rate round-trip remains exact', () {
    final original = CurrencyExchangeRate(
      sourceCurrency: 'EUR',
      targetCurrency: 'JPY',
      numerator: BigInt.from(162345),
      denominator: BigInt.from(1000),
      observedAt: DateTime.utc(2026, 11, 1),
      isManual: true,
    );

    final restored = BudgetExchangeRateCodec.decode(
      BudgetExchangeRateCodec.encode(original),
    );

    expect(restored.numerator, original.numerator);
    expect(restored.denominator, original.denominator);
    expect(restored.isManual, isTrue);
    expect(restored.observedAt, original.observedAt);
  });

  test('invalid denominator is rejected', () {
    final data = {
      'sourceCurrency': 'EUR',
      'targetCurrency': 'JPY',
      'numerator': '160',
      'denominator': '0',
      'observedAt': '2026-11-01T00:00:00.000Z',
      'isManual': false,
    };

    expect(() => BudgetExchangeRateCodec.decode(data), throwsArgumentError);
  });
}
