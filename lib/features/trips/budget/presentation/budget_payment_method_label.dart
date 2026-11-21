// Nome visibile di un metodo di pagamento, con gli stessi testi già usati
// dal pannello rimborsi (contanti, carta, bonifico, PayPal, Satispay, altro).

import '../models/budget_payment_allocation.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

String budgetPaymentMethodLabel(
  BudgetPaymentMethod method,
  AppLocalizations l10n,
) {
  switch (method) {
    case BudgetPaymentMethod.cash:
      return l10n.btMethodsCash;
    case BudgetPaymentMethod.card:
      return l10n.btMethodsCard;
    case BudgetPaymentMethod.bankTransfer:
      return l10n.btMethodsBankTransfer;
    case BudgetPaymentMethod.paypal:
      return 'PayPal';
    case BudgetPaymentMethod.satispay:
      return 'Satispay';
    case BudgetPaymentMethod.other:
      return l10n.btMethodsOther;
  }
}
