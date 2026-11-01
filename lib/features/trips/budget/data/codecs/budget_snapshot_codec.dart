import '../../models/expense_financial_snapshot.dart';
import '../../models/expense_payment_status.dart';
import '../../models/money_amount.dart';
import 'budget_money_codec.dart';

abstract final class BudgetSnapshotCodec {
  static Map<String, dynamic> encode(ExpenseFinancialSnapshot value) => {
    'total': BudgetMoneyCodec.encode(value.total),
    'status': value.status.name,
    'shares': _encodeAmounts(value.shares),
    'advances': _encodeAmounts(value.advances),
  };

  static ExpenseFinancialSnapshot decode(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid expense snapshot.');
    }

    final value = Map<String, dynamic>.from(raw);
    final status = value['status'];

    if (status is! String) {
      throw const FormatException('Invalid expense status.');
    }

    final parsedStatus = switch (status) {
      'planned' => ExpensePaymentStatus.planned,
      'outstanding' => ExpensePaymentStatus.outstanding,
      'paid' => ExpensePaymentStatus.paid,
      _ => throw const FormatException('Unknown expense status.'),
    };

    return ExpenseFinancialSnapshot(
      total: BudgetMoneyCodec.decode(value['total']),
      status: parsedStatus,
      shares: _decodeAmounts(value['shares']),
      advances: _decodeAmounts(value['advances']),
    );
  }

  static Map<String, dynamic> _encodeAmounts(
    Map<String, MoneyAmount> amounts,
  ) => amounts.map(
    (uid, amount) => MapEntry(uid, BudgetMoneyCodec.encode(amount)),
  );

  static Map<String, MoneyAmount> _decodeAmounts(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid traveler amounts.');
    }

    final result = <String, MoneyAmount>{};

    for (final entry in raw.entries) {
      if (entry.key is! String) {
        throw const FormatException('Invalid traveler UID.');
      }

      final uid = entry.key as String;

      if (uid.trim().isEmpty || uid.contains('/')) {
        throw const FormatException('Invalid traveler UID.');
      }

      result[uid] = BudgetMoneyCodec.decode(entry.value);
    }

    return Map.unmodifiable(result);
  }
}
