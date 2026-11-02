import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_debt_overview_calculator.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_reimbursement.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/reimbursement_status.dart';

MoneyAmount euro(int minor) => MoneyAmount(currency: 'EUR', minorUnits: minor);

BudgetDebtSource expense(
  String id, {
  List<ExpenseReimbursement> reimbursements = const [],
}) => BudgetDebtSource(
  expenseId: id,
  snapshot: ExpenseFinancialSnapshot(
    total: euro(2000),
    status: ExpensePaymentStatus.paid,
    shares: {'anna': euro(1000), 'luca': euro(1000)},
    advances: {'anna': euro(2000)},
  ),
  reimbursements: reimbursements,
);

ExpenseReimbursement refund(
  String id,
  String expenseId,
  int minor,
  ReimbursementStatus status,
) => ExpenseReimbursement(
  id: id,
  expenseId: expenseId,
  debtorUid: 'luca',
  creditorUid: 'anna',
  amount: euro(minor),
  status: status,
);

void main() {
  test('original debt belongs to one expense', () {
    final rows = BudgetDebtOverviewCalculator.calculate([expense('flight')]);
    expect(rows, hasLength(1));
    expect(rows.single.debt.expenseId, 'flight');
    expect(rows.single.remainingMinorUnits, 1000);
  });

  test('only confirmed reimbursements reduce outstanding debt', () {
    final rows = BudgetDebtOverviewCalculator.calculate([
      expense(
        'flight',
        reimbursements: [
          refund('a', 'flight', 300, ReimbursementStatus.confirmed),
          refund('b', 'flight', 200, ReimbursementStatus.pending),
          refund('c', 'flight', 100, ReimbursementStatus.rejected),
        ],
      ),
    ]);

    expect(rows.single.remainingMinorUnits, 700);
    expect(rows.single.confirmedMinorUnits, 300);
    expect(rows.single.isSettled, isFalse);
  });

  test('fully reimbursed debt is marked settled', () {
    final rows = BudgetDebtOverviewCalculator.calculate([
      expense(
        'flight',
        reimbursements: [
          refund('a', 'flight', 400, ReimbursementStatus.confirmed),
          refund('b', 'flight', 600, ReimbursementStatus.confirmed),
        ],
      ),
    ]);

    expect(rows.single.remainingMinorUnits, 0);
    expect(rows.single.isSettled, isTrue);
  });

  test('different expenses are never automatically compensated', () {
    final rows = BudgetDebtOverviewCalculator.calculate([
      expense('flight'),
      expense('hotel'),
    ]);

    expect(rows, hasLength(2));
    expect(rows.map((row) => row.debt.expenseId).toSet(), {'flight', 'hotel'});
  });

  test('duplicate expense IDs are rejected', () {
    expect(
      () => BudgetDebtOverviewCalculator.calculate([
        expense('flight'),
        expense('flight'),
      ]),
      throwsArgumentError,
    );
  });

  test('unmatched reimbursements are rejected', () {
    expect(
      () => BudgetDebtOverviewCalculator.calculate([
        expense(
          'flight',
          reimbursements: [
            refund('wrong', 'hotel', 100, ReimbursementStatus.confirmed),
          ],
        ),
      ]),
      throwsArgumentError,
    );
  });
}
