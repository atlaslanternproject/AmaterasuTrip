import '../models/money_amount.dart';

/// Divides a nonnegative amount among unique participants.
///
/// Remainder units are assigned deterministically in the
/// order supplied by the caller.
abstract final class EqualSplitCalculator {
  static Map<String, MoneyAmount> split({
    required MoneyAmount amount,
    required List<String> participantUids,
  }) {
    if (amount.isNegative) {
      throw ArgumentError('Expense amount cannot be negative.');
    }

    if (participantUids.isEmpty) {
      throw ArgumentError('At least one participant is required.');
    }

    if (participantUids.any((uid) => uid.trim().isEmpty)) {
      throw ArgumentError('Participant UID cannot be empty.');
    }

    if (participantUids.toSet().length != participantUids.length) {
      throw ArgumentError('Participant UIDs must be unique.');
    }

    final count = participantUids.length;
    final base = amount.minorUnits ~/ count;
    final remainder = amount.minorUnits % count;

    final result = <String, MoneyAmount>{};

    for (var i = 0; i < count; i++) {
      result[participantUids[i]] = MoneyAmount(
        currency: amount.currency,
        minorUnits: base + (i < remainder ? 1 : 0),
      );
    }

    return Map.unmodifiable(result);
  }
}
