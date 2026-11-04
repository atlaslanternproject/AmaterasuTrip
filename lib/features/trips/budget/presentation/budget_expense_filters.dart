import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared filter contract: dashboard and expense list always agree.
class BudgetExpenseFilters {
  const BudgetExpenseFilters({
    this.category = '',
    this.status = '',
    this.days = 0,
    this.sort = 'newest',
  });

  final String category;
  final String status;
  final int days;
  final String sort;

  BudgetExpenseFilters copyWith({
    String? category,
    String? status,
    int? days,
    String? sort,
  }) => BudgetExpenseFilters(
    category: category ?? this.category,
    status: status ?? this.status,
    days: days ?? this.days,
    sort: sort ?? this.sort,
  );

  bool matches(Map<String, dynamic> doc, DateTime now) {
    if (doc['lifecycle'] == 'cancelled') {
      return false;
    }
    if (category.isNotEmpty && doc['category'] != category) {
      return false;
    }
    final snapshot = doc['snapshot'];
    if (status.isNotEmpty &&
        (snapshot is! Map || snapshot['status'] != status)) {
      return false;
    }
    if (days > 0) {
      final created = doc['createdAt'];
      if (created is! Timestamp ||
          created.toDate().isBefore(now.subtract(Duration(days: days)))) {
        return false;
      }
    }
    return true;
  }

  int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (sort == 'amount-desc' || sort == 'amount-asc') {
      final aa = _minor(a);
      final bb = _minor(b);
      final delta = aa.compareTo(bb);
      if (delta != 0) {
        return sort == 'amount-desc' ? -delta : delta;
      }
    }
    final aDate = a['createdAt'];
    final bDate = b['createdAt'];
    final left = aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
    final right = bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;
    return sort == 'oldest' ? left.compareTo(right) : right.compareTo(left);
  }

  // Raw amounts in different currencies are NOT truly comparable.
  // Cross-currency amount sorting must not be presented as a financial rank.
  static int _minor(Map<String, dynamic> data) {
    final snapshot = data['snapshot'];
    final total = snapshot is Map ? snapshot['total'] : null;
    final amount = total is Map ? total['minorUnits'] : null;
    return amount is int ? amount : 0;
  }
}
