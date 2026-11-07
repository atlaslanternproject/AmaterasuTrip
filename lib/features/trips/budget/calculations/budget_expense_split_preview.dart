/// Calculates expense shares in the original currency.
///
/// This class does not perform FX conversion or persist data.
abstract final class BudgetExpenseSplitPreview {
  static Map<String, int> calculate({
    required int totalMinor,
    required List<String> participants,
    Map<String, int>? customShares,
  }) {
    if (totalMinor <= 0 || totalMinor > 9007199254740991) {
      throw const FormatException('Invalid expense total.');
    }

    if (participants.isEmpty ||
        participants.length != participants.toSet().length ||
        participants.any((uid) => uid.isEmpty)) {
      throw const FormatException('Invalid participants.');
    }

    final sorted = participants.toList()..sort();

    if (customShares != null) {
      if (customShares.keys.toSet().difference(sorted.toSet()).isNotEmpty ||
          customShares.length != sorted.length) {
        throw const FormatException('Shares do not match participants.');
      }

      var sum = 0;

      for (final uid in sorted) {
        final value = customShares[uid];
        if (value == null || value < 0 || value > totalMinor) {
          throw const FormatException('Invalid share.');
        }
        sum += value;
      }

      if (sum != totalMinor) {
        throw const FormatException('Shares do not match total.');
      }

      return {for (final uid in sorted) uid: customShares[uid]!};
    }

    final base = totalMinor ~/ sorted.length;
    final remainder = totalMinor % sorted.length;

    return {
      for (var i = 0; i < sorted.length; i++)
        sorted[i]: base + (i < remainder ? 1 : 0),
    };
  }
}
