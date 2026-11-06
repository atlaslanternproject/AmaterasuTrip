/// The personal travel budget measures what the traveler owes,
/// regardless of who advanced the payment.
abstract final class PersonalBudgetSpendingCalculator {
  static Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : {};

  static bool isIncluded(Map<String, dynamic> expense) {
    if (expense['lifecycle'] == 'cancelled') return false;
    final status = _map(expense['snapshot'])['status'];
    return status == 'paid' || status == 'outstanding';
  }

  static ({int minorUnits, String currency})? ownShare(
    Map<String, dynamic> expense, {
    required String uid,
    required bool privateExpense,
  }) {
    if (!isIncluded(expense)) return null;

    final financial = _map(expense['snapshot']);
    final total = _map(financial['total']);
    final currency = total['currency'];

    if (currency is! String || currency.isEmpty) return null;

    final own = privateExpense ? total : _map(_map(financial['shares'])[uid]);

    final value = own['minorUnits'];

    if (own['currency'] != currency || value is! int || value < 0) {
      return null;
    }

    return (minorUnits: value, currency: currency);
  }
}
