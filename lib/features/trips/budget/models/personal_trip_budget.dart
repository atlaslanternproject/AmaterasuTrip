class PersonalTripBudget {
  const PersonalTripBudget({required this.amountMinor, required this.currency});

  final int amountMinor;
  final String currency;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  bool get isValid =>
      amountMinor > 0 &&
      amountMinor <= 9000000000000 &&
      _currencyPattern.hasMatch(currency);

  Map<String, dynamic> toMap() {
    if (!isValid) {
      throw ArgumentError('Invalid personal trip budget.');
    }
    return {'amountMinor': amountMinor, 'currency': currency};
  }

  static PersonalTripBudget? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;

    final amount = data['amountMinor'];
    final currency = data['currency'];

    if (amount is! int || currency is! String) {
      return null;
    }

    final result = PersonalTripBudget(amountMinor: amount, currency: currency);

    return result.isValid ? result : null;
  }

  int remainingMinor(int spentMinor) => amountMinor - spentMinor;

  bool isExceeded(int spentMinor) => spentMinor > amountMinor;

  int exceededMinor(int spentMinor) =>
      spentMinor > amountMinor ? spentMinor - amountMinor : 0;
}
