import '../models/money_amount.dart';

abstract final class CustomSplitValidator {
  static void validate({
    required MoneyAmount total,
    required Map<String, MoneyAmount> shares,
  }) {
    if (total.isNegative) {
      throw ArgumentError('Expense total cannot be negative.');
    }

    if (shares.isEmpty) {
      throw ArgumentError('At least one share is required.');
    }

    var sum = 0;

    for (final entry in shares.entries) {
      if (entry.key.trim().isEmpty) {
        throw ArgumentError('Participant UID cannot be empty.');
      }

      if (entry.value.currency != total.currency) {
        throw ArgumentError('Share currency mismatch.');
      }

      if (entry.value.isNegative) {
        throw ArgumentError('Share cannot be negative.');
      }

      sum += entry.value.minorUnits;
    }

    if (sum != total.minorUnits) {
      throw ArgumentError('Individual shares do not match total.');
    }
  }
}
