import '../calculations/currency_minor_units.dart';

/// Immutable amount stored in the smallest currency unit.
///
/// EUR 12.34 -> 1234 minor units.
/// JPY 1200  -> 1200 minor units.
///
/// Values are restricted to JavaScript-safe integers for Flutter Web.
class MoneyAmount {
  MoneyAmount({required this.currency, required this.minorUnits}) {
    CurrencyMinorUnits.decimals(currency);

    if (minorUnits.abs() > maxSafeMinorUnits) {
      throw RangeError.range(
        minorUnits,
        -maxSafeMinorUnits,
        maxSafeMinorUnits,
        'minorUnits',
      );
    }
  }

  static const int maxSafeMinorUnits = 9007199254740991;

  final String currency;
  final int minorUnits;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;

  MoneyAmount operator +(MoneyAmount other) {
    _requireSameCurrency(other);
    return MoneyAmount(
      currency: currency,
      minorUnits: minorUnits + other.minorUnits,
    );
  }

  MoneyAmount operator -(MoneyAmount other) {
    _requireSameCurrency(other);
    return MoneyAmount(
      currency: currency,
      minorUnits: minorUnits - other.minorUnits,
    );
  }

  void _requireSameCurrency(MoneyAmount other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot combine different currencies.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MoneyAmount &&
      other.currency == currency &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(currency, minorUnits);

  @override
  String toString() => 'MoneyAmount($currency, $minorUnits)';
}
