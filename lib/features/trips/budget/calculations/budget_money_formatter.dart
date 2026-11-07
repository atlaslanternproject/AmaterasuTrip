import 'currency_minor_units.dart';

/// Formats accounting minor units without floating-point arithmetic.
///
/// It does not convert between currencies.
/// Unsupported currencies are rejected explicitly.
abstract final class BudgetMoneyFormatter {
  static String format(
    int minorUnits,
    String currency, {
    String decimalSeparator = ',',
    bool includeCurrency = true,
  }) {
    if (decimalSeparator != ',' && decimalSeparator != '.') {
      throw ArgumentError.value(
        decimalSeparator,
        'decimalSeparator',
        'Unsupported decimal separator',
      );
    }

    final digits = CurrencyMinorUnits.decimals(currency);
    final factor = CurrencyMinorUnits.factor(currency);

    final sign = minorUnits < 0 ? '-' : '';
    final absolute = minorUnits.abs();
    final whole = absolute ~/ factor;
    final fraction = absolute % factor;

    final value = digits == 0
        ? '$sign$whole'
        : '$sign$whole$decimalSeparator${fraction.toString().padLeft(digits, '0')}';

    return includeCurrency ? '$value $currency' : value;
  }
}
