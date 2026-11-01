import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/expense_debt_calculator.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

void main() {
  test('opposite debts from different expenses stay separate', () {
    final first = ExpenseDebtCalculator.calculate(
      expenseId: 'expenseA',
      expense: ExpenseFinancialSnapshot(
        total: eur(2000),
        status: ExpensePaymentStatus.paid,
        shares: {'anna': eur(1000), 'luca': eur(1000)},
        advances: {'anna': eur(2000)},
      ),
    );

    final second = ExpenseDebtCalculator.calculate(
      expenseId: 'expenseB',
      expense: ExpenseFinancialSnapshot(
        total: eur(2000),
        status: ExpensePaymentStatus.paid,
        shares: {'anna': eur(1000), 'luca': eur(1000)},
        advances: {'luca': eur(2000)},
      ),
    );

    expect(first.single.debtorUid, 'luca');
    expect(first.single.creditorUid, 'anna');
    expect(first.single.amount.minorUnits, 1000);

    expect(second.single.debtorUid, 'anna');
    expect(second.single.creditorUid, 'luca');
    expect(second.single.amount.minorUnits, 1000);

    expect(first.single.expenseId, 'expenseA');
    expect(second.single.expenseId, 'expenseB');
  });
}
