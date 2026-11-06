import 'budget_payment_allocation.dart';

/// Validates a complete declaration against the financial snapshot.
///
/// The expense snapshot remains the source of truth for how much
/// each traveler has advanced. Methods only describe those advances.
class BudgetPaymentPlan {
  const BudgetPaymentPlan(this.allocations);

  final List<BudgetPaymentAllocation> allocations;

  static const maxAllocations = 100;

  Map<String, int> get amountByPayer {
    final result = <String, int>{};

    for (final entry in allocations) {
      result.update(
        entry.payerUid,
        (existing) => existing + entry.minorUnits,
        ifAbsent: () => entry.minorUnits,
      );
    }

    return result;
  }

  int get totalMinor {
    var total = 0;

    for (final entry in allocations) {
      total += entry.minorUnits;
    }

    return total;
  }

  Set<String> approvalsRequired(String recorderUid) {
    return {
      for (final entry in allocations)
        if (entry.payerUid != recorderUid) entry.payerUid,
    };
  }

  /// [status] must be planned, outstanding or paid.
  /// [advancesMinor] contains amounts actually advanced per traveler.
  void validate({
    required String status,
    required int expenseTotalMinor,
    required Map<String, int> advancesMinor,
    required Set<String> activeTravelerUids,
  }) {
    if (!const {'planned', 'outstanding', 'paid'}.contains(status)) {
      throw const FormatException('Invalid payment status.');
    }

    if (expenseTotalMinor <= 0 || expenseTotalMinor > 9007199254740991) {
      throw const FormatException('Invalid expense total.');
    }

    if (allocations.length > maxAllocations) {
      throw const FormatException('Too many payment allocations.');
    }

    for (final entry in allocations) {
      if (!entry.isValid) {
        throw const FormatException('Invalid payment method or amount.');
      }

      if (!activeTravelerUids.contains(entry.payerUid)) {
        throw const FormatException('Unknown payer.');
      }
    }

    final declared = amountByPayer;
    final allPayers = {...declared.keys, ...advancesMinor.keys};

    for (final uid in allPayers) {
      final expected = advancesMinor[uid] ?? 0;
      final actual = declared[uid] ?? 0;

      if (expected < 0 || expected != actual) {
        throw const FormatException(
          'Payment methods do not match payer advances.',
        );
      }
    }

    final sum = totalMinor;

    if (sum > expenseTotalMinor) {
      throw const FormatException('Payment exceeds expense.');
    }

    if (status == 'planned' && sum != 0) {
      throw const FormatException(
        'Planned expense cannot contain actual payments.',
      );
    }

    if (status == 'paid' && sum != expenseTotalMinor) {
      throw const FormatException('Paid expense must be paid in full.');
    }

    if (status == 'outstanding' && sum >= expenseTotalMinor) {
      throw const FormatException(
        'Outstanding expense must have an unpaid remainder.',
      );
    }
  }

  List<Map<String, dynamic>> toPayload() {
    return [for (final allocation in allocations) allocation.toMap()];
  }

  static BudgetPaymentPlan? fromPayload(dynamic raw) {
    if (raw is! List || raw.length > maxAllocations) return null;

    final items = <BudgetPaymentAllocation>[];

    for (final entry in raw) {
      if (entry is! Map) return null;

      final item = BudgetPaymentAllocation.fromMap(
        Map<String, dynamic>.from(entry),
      );

      if (item == null) return null;
      items.add(item);
    }

    return BudgetPaymentPlan(items);
  }
}
