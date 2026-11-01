import '../calculations/currency_minor_units.dart';

/// Exact exchange rate: target major units per source major unit.
///
/// For example 1 EUR = 160 JPY:
/// numerator = 160, denominator = 1.
///
/// Rate metadata can be stored with the expense later.
class CurrencyExchangeRate {
  CurrencyExchangeRate({
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.numerator,
    required this.denominator,
    required this.observedAt,
    required this.isManual,
  }) {
    CurrencyMinorUnits.decimals(sourceCurrency);
    CurrencyMinorUnits.decimals(targetCurrency);

    if (numerator <= BigInt.zero || denominator <= BigInt.zero) {
      throw ArgumentError('Exchange rate must be positive.');
    }
  }

  final String sourceCurrency;
  final String targetCurrency;
  final BigInt numerator;
  final BigInt denominator;
  final DateTime observedAt;
  final bool isManual;
}
