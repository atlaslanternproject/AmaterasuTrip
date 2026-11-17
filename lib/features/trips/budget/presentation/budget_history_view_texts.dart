// Parte di budget_history_view.dart: frase e icona di ogni operazione,
// con i nomi al posto degli identificativi.

part of 'budget_history_view.dart';

/// Sentence describing one operation, with names instead of internal IDs.
String budgetHistoryText(
  BudgetHistoryEvent event,
  AppLocalizations l10n,
  String Function(String? uid) nameOf,
) {
  final actor = nameOf(event.actorUid);
  final other = nameOf(event.counterpartUid);
  switch (event.type) {
    case 'created':
      return l10n.b86EvCreated(actor);
    case 'revised':
      return l10n.b86EvRevised(actor, '${event.version ?? '—'}');
    case 'reimbursementRequested':
      return l10n.b86EvRefundRequested(actor, other);
    case 'reimbursementConfirmed':
      return l10n.b86EvRefundConfirmed(actor, other);
    case 'reimbursementRejected':
      return l10n.b86EvRefundRejected(actor, other);
    case 'debtClosed':
      return l10n.b86EvDebtClosed(actor, other);
    case 'cancellationRequested':
      return l10n.b86EvCancelRequested(actor);
    case 'cancellationApproved':
      return l10n.b86EvCancelApproved(actor);
    case 'cancellationRejected':
      return l10n.b86EvCancelRejected(actor);
    case 'cancelled':
      return l10n.b86EvCancelled(actor);
    case 'rateChanged':
      return l10n.b86EvRateChanged(actor, '${event.rate ?? '—'}');
    default:
      return l10n.b86EvUnknown;
  }
}

IconData budgetHistoryIcon(String type) {
  switch (type) {
    case 'created':
      return Icons.add_circle_outline;
    case 'revised':
      return Icons.edit_outlined;
    case 'reimbursementRequested':
      return Icons.payments_outlined;
    case 'reimbursementConfirmed':
      return Icons.check_circle_outline;
    case 'reimbursementRejected':
    case 'cancellationRejected':
      return Icons.cancel_outlined;
    case 'debtClosed':
      return Icons.task_alt_outlined;
    case 'cancellationRequested':
    case 'cancellationApproved':
    case 'cancelled':
      return Icons.block_outlined;
    case 'rateChanged':
      return Icons.currency_exchange;
    default:
      return Icons.history;
  }
}
