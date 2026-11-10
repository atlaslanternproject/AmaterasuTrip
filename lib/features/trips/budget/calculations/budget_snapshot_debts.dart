/// One debtor-creditor obligation inside a single paid expense.
class BudgetPairDebt {
  const BudgetPairDebt(this.debtorUid, this.creditorUid, this.minorUnits);

  final String debtorUid;
  final String creditorUid;
  final int minorUnits;

  @override
  bool operator ==(Object other) =>
      other is BudgetPairDebt &&
      other.debtorUid == debtorUid &&
      other.creditorUid == creditorUid &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(debtorUid, creditorUid, minorUnits);

  @override
  String toString() => '$debtorUid->$creditorUid:$minorUnits';
}

/// Debt allocation on raw Firestore expense data.
///
/// Mirrors `debtAmount` in functions/src/budget/budget-validation.ts:
/// travelers are sorted by ID, every debtor is matched against the
/// creditors in that order, and only fully paid expenses create debts.
/// The shared fixture test/fixtures/budget_debt_parity.json is checked
/// against both implementations.
abstract final class BudgetSnapshotDebts {
  /// Reimbursement statuses that reduce the original debt: confirmed
  /// reimbursements and closures of a former member's debt (B8.6).
  static const settledStatuses = {'confirmed', writtenOff};

  /// Status of a closure record (see closeBudgetDebt in Cloud Functions).
  static const writtenOff = 'writtenOff';

  static List<BudgetPairDebt> allocate(Object? rawSnapshot) {
    final snapshot = _map(rawSnapshot);
    if (snapshot['status'] != 'paid') {
      return const [];
    }

    final shares = _map(snapshot['shares']);
    final advances = _map(snapshot['advances']);
    final uids = {...shares.keys, ...advances.keys}.toList()..sort();

    final debtors = <String, int>{};
    final creditors = <String, int>{};

    for (final uid in uids) {
      final net = _minor(advances[uid]) - _minor(shares[uid]);
      if (net < 0) debtors[uid] = -net;
      if (net > 0) creditors[uid] = net;
    }

    final result = <BudgetPairDebt>[];
    for (final debtor in debtors.keys) {
      var remaining = debtors[debtor]!;
      for (final creditor in creditors.keys) {
        final available = creditors[creditor]!;
        final allocated = remaining < available ? remaining : available;
        if (allocated <= 0) continue;
        result.add(BudgetPairDebt(debtor, creditor, allocated));
        remaining -= allocated;
        creditors[creditor] = available - allocated;
      }
    }
    return List.unmodifiable(result);
  }

  /// Sum of reimbursement records of [statuses] for one debt pair.
  static int sumFor(
    Iterable<Map<String, dynamic>> refunds,
    String debtorUid,
    String creditorUid,
    Set<String> statuses,
  ) {
    var sum = 0;
    for (final refund in refunds) {
      final amount = refund['minorUnits'];
      if (refund['debtorUid'] == debtorUid &&
          refund['creditorUid'] == creditorUid &&
          statuses.contains(refund['status']) &&
          amount is int &&
          amount > 0) {
        sum += amount;
      }
    }
    return sum;
  }

  /// Remaining part of [debt], never below zero.
  static int remaining(
    BudgetPairDebt debt,
    Iterable<Map<String, dynamic>> refunds,
  ) {
    final settled = sumFor(
      refunds,
      debt.debtorUid,
      debt.creditorUid,
      settledStatuses,
    );
    final left = debt.minorUnits - settled;
    return left < 0 ? 0 : left;
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int _minor(Object? money) {
    final value = _map(money)['minorUnits'];
    return value is int ? value : 0;
  }
}
