import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/budget/models/money_amount.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_financial_snapshot.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_payment_status.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision_proposal.dart';
import 'package:amaterasutrip/features/trips/budget/models/expense_revision_approval.dart';
import 'package:amaterasutrip/features/trips/budget/policies/expense_revision_approval_policy.dart';

MoneyAmount eur(int cents) => MoneyAmount(currency: 'EUR', minorUnits: cents);

ExpenseFinancialSnapshot snapshot() => ExpenseFinancialSnapshot(
  total: eur(2000),
  status: ExpensePaymentStatus.paid,
  shares: {'anna': eur(1000), 'luca': eur(1000)},
  advances: {'anna': eur(2000)},
);

void main() {
  final current = ExpenseRevision(
    expenseId: 'dinner',
    number: 1,
    snapshot: snapshot(),
  );

  final proposal = ExpenseRevisionProposal(
    id: 'proposal1',
    expenseId: 'dinner',
    baseRevisionNumber: 1,
    proposedSnapshot: snapshot(),
  );

  ExpenseRevisionApproval approval(String uid, bool approved) =>
      ExpenseRevisionApproval(
        proposalId: 'proposal1',
        revisionNumber: 1,
        travelerUid: uid,
        approved: approved,
      );

  test('all affected travelers must approve', () {
    expect(
      () => ExpenseRevisionApprovalPolicy.validate(
        current: current,
        proposal: proposal,
        approvals: [approval('anna', true), approval('luca', true)],
      ),
      returnsNormally,
    );
  });

  test('missing approval blocks revision', () {
    expect(
      () => ExpenseRevisionApprovalPolicy.validate(
        current: current,
        proposal: proposal,
        approvals: [approval('anna', true)],
      ),
      throwsStateError,
    );
  });

  test('rejection blocks revision', () {
    expect(
      () => ExpenseRevisionApprovalPolicy.validate(
        current: current,
        proposal: proposal,
        approvals: [approval('anna', true), approval('luca', false)],
      ),
      throwsStateError,
    );
  });

  test('duplicate approval is rejected', () {
    expect(
      () => ExpenseRevisionApprovalPolicy.validate(
        current: current,
        proposal: proposal,
        approvals: [
          approval('anna', true),
          approval('anna', true),
          approval('luca', true),
        ],
      ),
      throwsStateError,
    );
  });

  test('stale proposal cannot be approved', () {
    final stale = ExpenseRevisionProposal(
      id: 'proposal1',
      expenseId: 'dinner',
      baseRevisionNumber: 2,
      proposedSnapshot: snapshot(),
    );

    expect(
      () => ExpenseRevisionApprovalPolicy.validate(
        current: current,
        proposal: stale,
        approvals: [approval('anna', true), approval('luca', true)],
      ),
      throwsStateError,
    );
  });
}
