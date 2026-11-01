import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_debt.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_reimbursement.dart';
import 'package:amaterasutrip/features/trips/budget/models/reimbursement_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/reimbursement_remaining_calculator.dart';

MoneyAmount yen(int value) => MoneyAmount(currency: 'JPY', minorUnits: value);

final debt = ExpenseDebt(
  expenseId: 'dinner',
  debtorUid: 'luca',
  creditorUid: 'anna',
  amount: yen(4000),
);

ExpenseReimbursement payment(String id, int value, ReimbursementStatus status) {
  return ExpenseReimbursement(
    id: id,
    expenseId: 'dinner',
    debtorUid: 'luca',
    creditorUid: 'anna',
    amount: yen(value),
    status: status,
  );
}

void main() {
  test('pending reimbursement does not reduce debt', () {
    final result = ReimbursementRemainingCalculator.calculate(
      debt: debt,
      reimbursements: [payment('r1', 1500, ReimbursementStatus.pending)],
    );

    expect(result.minorUnits, 4000);
  });

  test('confirmed partial reimbursement reduces debt', () {
    final result = ReimbursementRemainingCalculator.calculate(
      debt: debt,
      reimbursements: [payment('r1', 1500, ReimbursementStatus.confirmed)],
    );

    expect(result.minorUnits, 2500);
  });

  test('rejected reimbursement does not reduce debt', () {
    final result = ReimbursementRemainingCalculator.calculate(
      debt: debt,
      reimbursements: [payment('r1', 1500, ReimbursementStatus.rejected)],
    );

    expect(result.minorUnits, 4000);
  });

  test('multiple confirmed reimbursements close the debt', () {
    final result = ReimbursementRemainingCalculator.calculate(
      debt: debt,
      reimbursements: [
        payment('r1', 1500, ReimbursementStatus.confirmed),
        payment('r2', 2500, ReimbursementStatus.confirmed),
      ],
    );

    expect(result.minorUnits, 0);
  });

  test('excessive confirmed reimbursements are rejected', () {
    expect(
      () => ReimbursementRemainingCalculator.calculate(
        debt: debt,
        reimbursements: [payment('r1', 4100, ReimbursementStatus.confirmed)],
      ),
      throwsArgumentError,
    );
  });

  test('duplicate reimbursement IDs are rejected', () {
    expect(
      () => ReimbursementRemainingCalculator.calculate(
        debt: debt,
        reimbursements: [
          payment('r1', 1000, ReimbursementStatus.confirmed),
          payment('r1', 1000, ReimbursementStatus.confirmed),
        ],
      ),
      throwsArgumentError,
    );
  });
}
