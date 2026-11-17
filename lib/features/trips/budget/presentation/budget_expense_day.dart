import 'package:cloud_firestore/cloud_firestore.dart';

final _isoDay = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// The effective day of an expense.
///
/// Uses `expenseDate` (a calendar day "YYYY-MM-DD", validated by the
/// Cloud Functions) and falls back to `createdAt` for records created
/// before the effective date existed or when the stored value is not a
/// real calendar day. Never invents a date.
DateTime? budgetExpenseDay(Map<String, dynamic> expense) {
  final day = expense['expenseDate'];
  if (day is String) {
    final match = _isoDay.firstMatch(day.trim());
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final date = int.parse(match.group(3)!);
      final parsed = DateTime(year, month, date);
      // DateTime silently rolls 2025-02-30 over to March: reject it.
      if (parsed.year == year && parsed.month == month && parsed.day == date) {
        return parsed;
      }
    }
  }
  final created = expense['createdAt'];
  return created is Timestamp ? created.toDate() : null;
}
