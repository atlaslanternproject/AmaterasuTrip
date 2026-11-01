import '../../models/money_amount.dart';

/// Explicit Firestore-compatible representation of MoneyAmount.
///
/// Minor units remain integers, never floating-point values.
abstract final class BudgetMoneyCodec {
  static Map<String, dynamic> encode(MoneyAmount value) => {
    'currency': value.currency,
    'minorUnits': value.minorUnits,
  };

  static MoneyAmount decode(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid money object.');
    }

    final value = Map<String, dynamic>.from(raw);
    final currency = value['currency'];
    final units = value['minorUnits'];

    if (currency is! String || units is! int) {
      throw const FormatException('Invalid money fields.');
    }

    return MoneyAmount(currency: currency, minorUnits: units);
  }
}
