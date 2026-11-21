// Dati scelti nel dialogo "Segna come pagato" e loro trasformazione
// nel formato dei metodi di pagamento che il server accetta.

import '../models/budget_payment_allocation.dart';

class BudgetDeclaredPaymentResult {
  const BudgetDeclaredPaymentResult({
    required this.minorUnits,
    required this.paidOn,
    required this.note,
    this.method,
    this.otherLabel,
  });

  /// [day] as YYYY-MM-DD, the format of [paidOn].
  static String dayText(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  final int minorUnits;

  /// Day of the payment, YYYY-MM-DD.
  final String paidOn;

  /// Empty when no note was written.
  final String note;
  final BudgetPaymentMethod? method;
  final String? otherLabel;

  /// Method as sent to the server (paid entirely by [debtorUid]),
  /// or null when no method was chosen.
  List<Map<String, dynamic>>? paymentMethodsFor(String debtorUid) {
    final chosen = method;
    if (chosen == null) return null;
    return [
      BudgetPaymentAllocation(
        payerUid: debtorUid,
        method: chosen,
        minorUnits: minorUnits,
        otherLabel: chosen == BudgetPaymentMethod.other ? otherLabel : null,
      ).toMap(),
    ];
  }
}
