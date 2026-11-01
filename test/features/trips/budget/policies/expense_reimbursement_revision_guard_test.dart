import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_reimbursement.dart';
import 'package:amaterasutrip/features/trips/budget/models/reimbursement_status.dart';
import 'package:amaterasutrip/features/trips/budget/policies/expense_reimbursement_revision_guard.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

ExpenseRevision revision(int version, int annaShare) => ExpenseRevision(
  expenseId: 'dinner',
  number: version,
  snapshot: ExpenseFinancialSnapshot(
    total: eur(2000),
    status: ExpensePaymentStatus.paid,
    shares: {'anna': eur(annaShare), 'luca': eur(2000 - annaShare)},
    advances: {'anna': eur(2000)},
  ),
);

ExpenseReimbursement reimbursement(ReimbursementStatus status) =>
    ExpenseReimbursement(
      id: 'refund1',
      expenseId: 'dinner',
      debtorUid: 'luca',
      creditorUid: 'anna',
      amount: eur(500),
      status: status,
    );

void main() {
  test('confirmed reimbursement freezes original debt', () {
    expect(
      () => ExpenseReimbursementRevisionGuard.validate(
        current: revision(1, 1000),
        proposed: revision(2, 1200),
        reimbursements: [reimbursement(ReimbursementStatus.confirmed)],
      ),
      throwsStateError,
    );
  });

  test('unchanged debt can retain confirmed reimbursement', () {
    expect(
      () => ExpenseReimbursementRevisionGuard.validate(
        current: revision(1, 1000),
        proposed: revision(2, 1000),
        reimbursements: [reimbursement(ReimbursementStatus.confirmed)],
      ),
      returnsNormally,
    );
  });

  test('pending reimbursement does not freeze debt', () {
    expect(
      () => ExpenseReimbursementRevisionGuard.validate(
        current: revision(1, 1000),
        proposed: revision(2, 1200),
        reimbursements: [reimbursement(ReimbursementStatus.pending)],
      ),
      returnsNormally,
    );
  });

  test('unrelated expense reimbursement is rejected', () {
    final unrelated = ExpenseReimbursement(
      id: 'refund-other',
      expenseId: 'hotel',
      debtorUid: 'luca',
      creditorUid: 'anna',
      amount: eur(500),
      status: ReimbursementStatus.confirmed,
    );

    expect(
      () => ExpenseReimbursementRevisionGuard.validate(
        current: revision(1, 1000),
        proposed: revision(2, 1000),
        reimbursements: [unrelated],
      ),
      throwsArgumentError,
    );
  });
}
