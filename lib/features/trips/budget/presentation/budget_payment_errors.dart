// Messaggi chiari per gli errori del server legati ai pagamenti
// registrati dal creditore. Per gli altri errori restituisce null e il
// pannello mostra il messaggio di sempre.

import 'package:amaterasutrip/l10n/app_localizations.dart';

String? budgetPaymentErrorText(String? serverMessage, AppLocalizations l10n) {
  switch (serverMessage) {
    case 'Reimbursement exceeds remaining debt.':
      return l10n.btPaidRequestExceeds;
    case 'Amount exceeds remaining debt.':
      return l10n.btPaidAmountTooHigh;
    case 'Debt already closed.':
      return l10n.btPaidDebtClosed;
    default:
      return null;
  }
}
