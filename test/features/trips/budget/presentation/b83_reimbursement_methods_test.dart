import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/budget_payment_allocation.dart';

void main() {
  test('B8.3 multiple reimbursement methods', () {
    const cash = BudgetPaymentAllocation(
      payerUid: 'debtor',
      method: BudgetPaymentMethod.cash,
      minorUnits: 800,
    );
    const transfer = BudgetPaymentAllocation(
      payerUid: 'debtor',
      method: BudgetPaymentMethod.bankTransfer,
      minorUnits: 1200,
    );

    expect(cash.isValid, isTrue);
    expect(transfer.isValid, isTrue);
    expect(cash.minorUnits + transfer.minorUnits, 2000);
    expect(
      BudgetPaymentAllocation.fromMap(cash.toMap())?.method,
      BudgetPaymentMethod.cash,
    );
  });

  test('B8.3 invalid payment allocation', () {
    const invalid = BudgetPaymentAllocation(
      payerUid: 'debtor',
      method: BudgetPaymentMethod.other,
      minorUnits: 100,
    );
    expect(invalid.isValid, isFalse);
  });
}
