// Dialogo per annullare un pagamento registrato dal creditore: chiede il
// motivo (almeno 3 caratteri) e lo restituisce. Non salva nulla.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class BudgetVoidPaymentDialog extends StatefulWidget {
  const BudgetVoidPaymentDialog({super.key, required this.summary});

  /// Who paid and how much, shown in bold at the top.
  final String summary;

  @override
  State<BudgetVoidPaymentDialog> createState() =>
      _BudgetVoidPaymentDialogState();
}

class _BudgetVoidPaymentDialogState extends State<BudgetVoidPaymentDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valid = _reason.text.trim().length >= 3;
    return AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.btPaidVoidTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.summary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AmaterasuSpacing.sm),
            Text(
              l10n.btPaidVoidBody,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('paid-void-reason'),
              controller: _reason,
              maxLength: 400,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.btPaidVoidReason),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.btActionCancel),
        ),
        FilledButton(
          key: const Key('paid-void-confirm'),
          onPressed: valid
              ? () => Navigator.pop(context, _reason.text.trim())
              : null,
          child: Text(l10n.btPaidVoidAction),
        ),
      ],
    );
  }
}
