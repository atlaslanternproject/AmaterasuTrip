import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision_proposal.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision_approval.dart';
import 'package:amaterasutrip/features/trips/budget/services/expense_revision_service.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

ExpenseFinancialSnapshot snapshot({required int annaShare}) =>
    ExpenseFinancialSnapshot(
      total: eur(2000),
      status: ExpensePaymentStatus.paid,
      shares: {'anna': eur(annaShare), 'luca': eur(2000 - annaShare)},
      advances: {'anna': eur(2000)},
    );

void main() {
  final current = ExpenseRevision(
    expenseId: 'dinner',
    number: 1,
    snapshot: snapshot(annaShare: 1000),
  );

  final proposal = ExpenseRevisionProposal(
    id: 'p1',
    expenseId: 'dinner',
    baseRevisionNumber: 1,
    proposedSnapshot: snapshot(annaShare: 1200),
  );

  final approvals = [
    const ExpenseRevisionApproval(
      proposalId: 'p1',
      revisionNumber: 1,
      travelerUid: 'anna',
      approved: true,
    ),
    const ExpenseRevisionApproval(
      proposalId: 'p1',
      revisionNumber: 1,
      travelerUid: 'luca',
      approved: true,
    ),
  ];

  test('approved revision increments version', () {
    final result = ExpenseRevisionService.apply(
      current: current,
      proposal: proposal,
      approvals: approvals,
      reimbursements: [],
    );

    expect(result.number, 2);
    expect(result.snapshot.shares['anna']!.minorUnits, 1200);
    expect(current.number, 1);
    expect(current.snapshot.shares['anna']!.minorUnits, 1000);
  });

  test('missing approval leaves revision unapplied', () {
    expect(
      () => ExpenseRevisionService.apply(
        current: current,
        proposal: proposal,
        approvals: [approvals.first],
        reimbursements: [],
      ),
      throwsStateError,
    );

    expect(current.number, 1);
  });

  test('unchanged proposal is rejected', () {
    final unchanged = ExpenseRevisionProposal(
      id: 'p1',
      expenseId: 'dinner',
      baseRevisionNumber: 1,
      proposedSnapshot: snapshot(annaShare: 1000),
    );

    expect(
      () => ExpenseRevisionService.apply(
        current: current,
        proposal: unchanged,
        approvals: approvals,
        reimbursements: [],
      ),
      throwsStateError,
    );
  });

  test('revision snapshot cannot be mutated externally', () {
    expect(
      () => current.snapshot.shares['anna'] = eur(500),
      throwsUnsupportedError,
    );
  });
}
