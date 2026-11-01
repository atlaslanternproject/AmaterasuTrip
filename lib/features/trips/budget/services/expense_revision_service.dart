import '../calculations/expense_financial_validator.dart';
import '../models/expense_revision.dart';
import '../models/expense_revision_proposal.dart';
import '../models/expense_revision_approval.dart';
import '../models/expense_reimbursement.dart';
import '../models/money_amount.dart';
import '../models/expense_financial_snapshot.dart';
import '../policies/expense_revision_approval_policy.dart';
import '../policies/expense_reimbursement_revision_guard.dart';

/// Pure revision coordinator; does not persist or authenticate data.
abstract final class ExpenseRevisionService {
  static ExpenseRevision apply({
    required ExpenseRevision current,
    required ExpenseRevisionProposal proposal,
    required List<ExpenseRevisionApproval> approvals,
    required List<ExpenseReimbursement> reimbursements,
  }) {
    ExpenseFinancialValidator.validate(current.snapshot);
    ExpenseFinancialValidator.validate(proposal.proposedSnapshot);

    if (_sameSnapshot(current.snapshot, proposal.proposedSnapshot)) {
      throw StateError('Revision has no financial changes.');
    }

    ExpenseRevisionApprovalPolicy.validate(
      current: current,
      proposal: proposal,
      approvals: approvals,
    );

    final next = ExpenseRevision(
      expenseId: current.expenseId,
      number: current.number + 1,
      snapshot: proposal.proposedSnapshot,
    );

    ExpenseReimbursementRevisionGuard.validate(
      current: current,
      proposed: next,
      reimbursements: reimbursements,
    );

    return next;
  }

  static bool _sameSnapshot(
    ExpenseFinancialSnapshot a,
    ExpenseFinancialSnapshot b,
  ) {
    return a.total == b.total &&
        a.status == b.status &&
        _sameAmounts(a.shares, b.shares) &&
        _sameAmounts(a.advances, b.advances);
  }

  static bool _sameAmounts(
    Map<String, MoneyAmount> a,
    Map<String, MoneyAmount> b,
  ) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }

    return true;
  }
}
