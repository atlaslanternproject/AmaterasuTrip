import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'budget_api.dart';

/// Manual provider correction. Audited by a callable; never edits any debt.
class BudgetFxManualDialog extends StatefulWidget {
  const BudgetFxManualDialog({
    super.key,
    required this.api,
    required this.expenseId,
    required this.private,
    required this.from,
    required this.to,
  });

  final BudgetApi api;
  final String expenseId;
  final bool private;
  final String from;
  final String to;

  @override
  State<BudgetFxManualDialog> createState() => _BudgetFxManualDialogState();
}

class _BudgetFxManualDialogState extends State<BudgetFxManualDialog> {
  final _rate = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_rate.text.trim().replaceAll(',', '.'));
    if (parsed == null ||
        !parsed.isFinite ||
        parsed <= 0 ||
        _reason.text.trim().length < 3) {
      setState(() => _error = AppLocalizations.of(context)!.b6InvalidRate);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.overrideExpenseFx(
        expenseId: widget.expenseId,
        private: widget.private,
        rate: parsed,
        reason: _reason.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: const Color(0xFF241A16),
      title: Text(l10n.b6ManualRate),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1 ${widget.from} → ${widget.to}'),
            const SizedBox(height: 12),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.b6RateValue,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLength: 400,
              decoration: InputDecoration(
                labelText: l10n.b6RateReason,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFFB4A2))),
            Text(
              l10n.b6RateDoesNotChangeDebts,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB7A99B)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.b6Cancel),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.b6Save)),
      ],
    );
  }
}
