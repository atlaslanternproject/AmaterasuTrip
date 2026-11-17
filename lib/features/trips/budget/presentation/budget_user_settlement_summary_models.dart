// Parte di budget_user_settlement_summary.dart: righe di debito
// e movimenti mostrati nel riepilogo.

part of 'budget_user_settlement_summary.dart';

class _DebtLine {
  const _DebtLine(this.debtor, this.creditor, this.amount);
  final String debtor;
  final String creditor;
  final int amount;
}

class _Movement {
  const _Movement({
    required this.debtor,
    required this.creditor,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.expenseTitle,
    required this.expense,
  });

  final String debtor;
  final String creditor;
  final int amount;
  final String currency;
  final String status;
  final DateTime? date;
  final String expenseTitle;
  final Map<String, dynamic> expense;
}
