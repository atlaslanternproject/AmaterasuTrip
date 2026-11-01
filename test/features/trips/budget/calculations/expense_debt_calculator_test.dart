import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/expense_debt_calculator.dart';

MoneyAmount yen(int value) => MoneyAmount(currency: 'JPY', minorUnits: value);

void main() {
  test('one payer, three beneficiaries', () {
    final debts = ExpenseDebtCalculator.calculate(
      expenseId: 'dinner',
      expense: ExpenseFinancialSnapshot(
        total: yen(12000),
        status: ExpensePaymentStatus.paid,
        shares: {'anna': yen(4000), 'luca': yen(4000), 'marco': yen(4000)},
        advances: {'anna': yen(12000)},
      ),
    );

    expect(debts.length, 2);
    expect(debts[0].debtorUid, 'luca');
    expect(debts[0].creditorUid, 'anna');
    expect(debts[0].amount.minorUnits, 4000);
    expect(debts[1].debtorUid, 'marco');
    expect(debts[1].amount.minorUnits, 4000);
  });

  test('multiple payers allocate only net creditor balances', () {
    final debts = ExpenseDebtCalculator.calculate(
      expenseId: 'hotel',
      expense: ExpenseFinancialSnapshot(
        total: yen(12000),
        status: ExpensePaymentStatus.paid,
        shares: {'anna': yen(4000), 'luca': yen(4000), 'marco': yen(4000)},
        advances: {'anna': yen(7000), 'luca': yen(5000)},
      ),
    );

    expect(debts.length, 2);
    expect(debts[0].debtorUid, 'marco');
    expect(debts[0].creditorUid, 'anna');
    expect(debts[0].amount.minorUnits, 3000);
    expect(debts[1].creditorUid, 'luca');
    expect(debts[1].amount.minorUnits, 1000);
  });

  test('everyone pays their own share: no debts', () {
    final debts = ExpenseDebtCalculator.calculate(
      expenseId: 'tickets',
      expense: ExpenseFinancialSnapshot(
        total: yen(6000),
        status: ExpensePaymentStatus.paid,
        shares: {'anna': yen(3000), 'luca': yen(3000)},
        advances: {'anna': yen(3000), 'luca': yen(3000)},
      ),
    );

    expect(debts, isEmpty);
  });

  test('outstanding supplier payment blocks final debts', () {
    expect(
      () => ExpenseDebtCalculator.calculate(
        expenseId: 'hotel',
        expense: ExpenseFinancialSnapshot(
          total: yen(12000),
          status: ExpensePaymentStatus.outstanding,
          shares: {'anna': yen(6000), 'luca': yen(6000)},
          advances: {'anna': yen(3000)},
        ),
      ),
      throwsStateError,
    );
  });
}
