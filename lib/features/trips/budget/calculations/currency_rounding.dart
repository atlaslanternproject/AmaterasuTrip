/// Rounds an exact rational number to the nearest integer.
///
/// Halfway values are rounded away from zero.
/// No floating-point arithmetic is used.
abstract final class CurrencyRounding {
  static BigInt divide(BigInt numerator, BigInt denominator) {
    if (denominator <= BigInt.zero) {
      throw ArgumentError('Denominator must be positive.');
    }

    final negative = numerator < BigInt.zero;
    final magnitude = numerator.abs();
    final whole = magnitude ~/ denominator;
    final remainder = magnitude.remainder(denominator);

    final rounded = remainder * BigInt.two >= denominator
        ? whole + BigInt.one
        : whole;

    return negative ? -rounded : rounded;
  }
}
