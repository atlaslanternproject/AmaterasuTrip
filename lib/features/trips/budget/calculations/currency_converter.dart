import '../models/money_amount.dart';
import '../models/currency_exchange_rate.dart';
import 'currency_minor_units.dart';
import 'currency_rounding.dart';

abstract final class CurrencyConverter {
  static MoneyAmount convert({
    required MoneyAmount amount,
    required CurrencyExchangeRate rate,
  }) {
    if (amount.currency != rate.sourceCurrency) {
      throw ArgumentError('Exchange rate source currency mismatch.');
    }

    final sourceFactor = CurrencyMinorUnits.factor(rate.sourceCurrency);
    final targetFactor = CurrencyMinorUnits.factor(rate.targetCurrency);

    final numerator =
        BigInt.from(amount.minorUnits) *
        rate.numerator *
        BigInt.from(targetFactor);

    final denominator = rate.denominator * BigInt.from(sourceFactor);

    final converted = CurrencyRounding.divide(numerator, denominator);

    if (converted.abs() > BigInt.from(MoneyAmount.maxSafeMinorUnits)) {
      throw RangeError('Converted amount exceeds safe integer range.');
    }

    return MoneyAmount(
      currency: rate.targetCurrency,
      minorUnits: converted.toInt(),
    );
  }
}
