// Parte di budget_reimbursements_panel.dart: dialogo che chiede
// il motivo della chiusura di un debito.

part of 'budget_reimbursements_panel.dart';

/// B8.6: asks the creditor for the reason of a debt closure.
class _CloseDebtDialog extends StatefulWidget {
  const _CloseDebtDialog({required this.debtorName});

  final String debtorName;

  @override
  State<_CloseDebtDialog> createState() => _CloseDebtDialogState();
}

class _CloseDebtDialogState extends State<_CloseDebtDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valid = _controller.text.trim().length >= 3;
    return AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.b86CloseDebtTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.debtorName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AmaterasuSpacing.sm),
            Text(
              l10n.b86CloseDebtExplain,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('b86-close-reason'),
              controller: _controller,
              maxLength: 400,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.b86CloseDebtReason),
            ),
            if (!valid)
              Text(
                l10n.b86CloseDebtInvalid,
                style: const TextStyle(color: AmaterasuColors.accentErrorSoft, fontSize: 12),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.b6Cancel),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: Text(l10n.b86CloseDebt),
        ),
      ],
    );
  }
}
