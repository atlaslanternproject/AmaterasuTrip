/// A declared payment method; it does not trigger a real payment.
enum BudgetPaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bankTransfer'),
  paypal('paypal'),
  satispay('satispay'),
  other('other');

  const BudgetPaymentMethod(this.code);

  final String code;

  static BudgetPaymentMethod? fromCode(String code) {
    for (final method in values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

/// One portion of an expense, paid by a particular traveler.
class BudgetPaymentAllocation {
  const BudgetPaymentAllocation({
    required this.payerUid,
    required this.method,
    required this.minorUnits,
    this.otherLabel,
    this.accountCurrency,
    this.accountDebitMinor,
  });

  final String payerUid;
  final BudgetPaymentMethod method;
  final int minorUnits;
  final String? otherLabel;
  final String? accountCurrency;
  final int? accountDebitMinor;

  static final RegExp _uidPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  bool get isValid {
    if (!_uidPattern.hasMatch(payerUid)) return false;
    if (minorUnits <= 0 || minorUnits > 9007199254740991) {
      return false;
    }

    if (accountCurrency != null &&
        !RegExp(r'^[A-Z]{3}$').hasMatch(accountCurrency!)) {
      return false;
    }
    if (accountDebitMinor != null &&
        (accountCurrency == null ||
            accountDebitMinor! <= 0 ||
            accountDebitMinor! > 9007199254740991)) {
      return false;
    }
    final label = otherLabel?.trim();

    if (method == BudgetPaymentMethod.other) {
      return label != null && label.isNotEmpty && label.length <= 40;
    }

    return label == null || label.isEmpty;
  }

  Map<String, dynamic> toMap() {
    if (!isValid) {
      throw ArgumentError('Invalid payment allocation.');
    }

    return {
      'payerUid': payerUid,
      'method': method.code,
      if (accountCurrency != null) 'accountCurrency': accountCurrency,
      if (accountDebitMinor != null) 'accountDebitMinor': accountDebitMinor,
      'minorUnits': minorUnits,
      if (method == BudgetPaymentMethod.other) 'otherLabel': otherLabel!.trim(),
    };
  }

  static BudgetPaymentAllocation? fromMap(Map<String, dynamic> data) {
    const allowed = {
      'payerUid',
      'method',
      'minorUnits',
      'otherLabel',
      'accountCurrency',
      'accountDebitMinor',
    };

    if (data.keys.any((key) => !allowed.contains(key))) {
      return null;
    }

    final uid = data['payerUid'];
    final methodCode = data['method'];
    final amount = data['minorUnits'];
    final label = data['otherLabel'];

    if (uid is! String ||
        methodCode is! String ||
        amount is! int ||
        (label != null && label is! String)) {
      return null;
    }

    final method = BudgetPaymentMethod.fromCode(methodCode);
    if (method == null) return null;

    final account = data['accountCurrency'];
    final debit = data['accountDebitMinor'];
    if ((account != null && account is! String) ||
        (debit != null && debit is! int)) {
      return null;
    }
    final result = BudgetPaymentAllocation(
      accountCurrency: account as String?,
      accountDebitMinor: debit as int?,
      payerUid: uid,
      method: method,
      minorUnits: amount,
      otherLabel: label as String?,
    );

    return result.isValid ? result : null;
  }
}
