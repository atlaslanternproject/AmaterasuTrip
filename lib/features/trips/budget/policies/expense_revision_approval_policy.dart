import '../models/expense_revision.dart';
import '../models/expense_revision_proposal.dart';
import '../models/expense_revision_approval.dart';

/// Conservative approval policy:
/// all affected travelers must explicitly approve.
abstract final class ExpenseRevisionApprovalPolicy {
  static Set<String> requiredTravelers({
    required ExpenseRevision current,
    required ExpenseRevisionProposal proposal,
  }) {
    return Set.unmodifiable({
      ...current.snapshot.shares.keys,
      ...current.snapshot.advances.keys,
      ...proposal.proposedSnapshot.shares.keys,
      ...proposal.proposedSnapshot.advances.keys,
    });
  }

  static void validate({
    required ExpenseRevision current,
    required ExpenseRevisionProposal proposal,
    required List<ExpenseRevisionApproval> approvals,
  }) {
    if (proposal.expenseId != current.expenseId ||
        proposal.baseRevisionNumber != current.number) {
      throw StateError('Proposal targets an outdated expense revision.');
    }

    final required = requiredTravelers(current: current, proposal: proposal);

    final seen = <String>{};

    for (final approval in approvals) {
      if (approval.proposalId != proposal.id ||
          approval.revisionNumber != current.number ||
          !required.contains(approval.travelerUid) ||
          !seen.add(approval.travelerUid)) {
        throw StateError('Invalid, duplicate or unrelated approval.');
      }

      if (!approval.approved) {
        throw StateError('An affected traveler rejected the revision.');
      }
    }

    if (seen.length != required.length) {
      throw StateError('Not all affected travelers have approved.');
    }
  }
}
