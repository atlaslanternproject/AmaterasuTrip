import '../models/money_amount.dart';

/// Validates and sums amounts actually paid by travelers.
///
/// The paid amount may be lower than the total expense
/// when an expense has an outstanding supplier balance.
abstract final class AdvanceTotalCalculator {
  static MoneyAmount sum({
    required String currency,
    required Map<String, MoneyAmount> advances,
  }) {
    if (advances.isEmpty) {
      throw ArgumentError('At least one advance is required.');
    }

    var minorUnits = 0;

    for (final entry in advances.entries) {
      if (entry.key.trim().isEmpty) {
        throw ArgumentError('Payer UID cannot be empty.');
      }

      if (entry.value.currency != currency) {
        throw ArgumentError('Advance currency mismatch.');
      }

      if (entry.value.isNegative) {
        throw ArgumentError('Advance cannot be negative.');
      }

      minorUnits += entry.value.minorUnits;
    }

    return MoneyAmount(currency: currency, minorUnits: minorUnits);
  }
}
