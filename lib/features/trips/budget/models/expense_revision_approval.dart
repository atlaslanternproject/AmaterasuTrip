/// Explicit decision concerning one proposed revision.
///
/// This is a domain value, not proof of user authentication.
/// Server-side identity verification is required before persistence.
class ExpenseRevisionApproval {
  const ExpenseRevisionApproval({
    required this.proposalId,
    required this.revisionNumber,
    required this.travelerUid,
    required this.approved,
  });

  final String proposalId;
  final int revisionNumber;
  final String travelerUid;
  final bool approved;
}
