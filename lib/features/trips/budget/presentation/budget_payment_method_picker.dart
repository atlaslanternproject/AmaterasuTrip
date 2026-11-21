// Scelta facoltativa di un metodo di pagamento (menu a tendina con
// "Non indicato"), più il campo di testo quando il metodo è "Altro".

import 'package:flutter/material.dart';

import '../models/budget_payment_allocation.dart';
import 'budget_payment_method_label.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class BudgetPaymentMethodPicker extends StatelessWidget {
  const BudgetPaymentMethodPicker({
    super.key,
    required this.method,
    required this.otherLabel,
    required this.onChanged,
  });

  final BudgetPaymentMethod? method;
  final TextEditingController otherLabel;

  /// Called when the method or the "other" text changes.
  final ValueChanged<BudgetPaymentMethod?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<BudgetPaymentMethod?>(
          key: const Key('paid-method'),
          initialValue: method,
          decoration: InputDecoration(labelText: l10n.btPaidMethod),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.btPaidMethodNone)),
            for (final value in BudgetPaymentMethod.values)
              DropdownMenuItem(
                value: value,
                child: Text(budgetPaymentMethodLabel(value, l10n)),
              ),
          ],
          onChanged: onChanged,
        ),
        if (method == BudgetPaymentMethod.other)
          TextField(
            key: const Key('paid-other-label'),
            controller: otherLabel,
            maxLength: 40,
            onChanged: (_) => onChanged(method),
            decoration: InputDecoration(labelText: l10n.btPaidMethodOther),
          ),
      ],
    );
  }
}
