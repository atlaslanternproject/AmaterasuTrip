import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? budgetExpenseDay(Map<String, dynamic> expense) {
  final day = expense['expenseDate'];
  if (day is String) {
    final parsed = DateTime.tryParse(day);
    if (parsed != null) return parsed;
  }
  final created = expense['createdAt'];
  return created is Timestamp ? created.toDate() : null;
}
