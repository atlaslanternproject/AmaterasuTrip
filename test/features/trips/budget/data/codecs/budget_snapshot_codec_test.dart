import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/data/codecs/budget_snapshot_codec.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

void main() {
  test('snapshot round-trip preserves all monetary fields', () {
    final original = ExpenseFinancialSnapshot(
      total: eur(12000),
      status: ExpensePaymentStatus.paid,
      shares: {'anna': eur(6000), 'luca': eur(6000)},
      advances: {'anna': eur(12000)},
    );

    final restored = BudgetSnapshotCodec.decode(
      BudgetSnapshotCodec.encode(original),
    );

    expect(restored.total, original.total);
    expect(restored.status, original.status);
    expect(restored.shares['luca'], eur(6000));
    expect(restored.advances['anna'], eur(12000));
  });

  test('unknown status fails closed', () {
    expect(
      () => BudgetSnapshotCodec.decode({
        'total': {'currency': 'EUR', 'minorUnits': 100},
        'status': 'unknown',
        'shares': {},
        'advances': {},
      }),
      throwsFormatException,
    );
  });
}
