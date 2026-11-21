// Dialogo "Segna come pagato": il creditore registra che un viaggiatore
// lo ha pagato. Importo (di default il residuo), data (di default oggi),
// metodo e nota facoltativi. Restituisce i dati, non salva nulla.

import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../models/budget_payment_allocation.dart';
import 'budget_declared_payment_result.dart';
import 'budget_money_input.dart';
import 'budget_payment_method_picker.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class BudgetDeclarePaymentDialog extends StatefulWidget {
  const BudgetDeclarePaymentDialog({
    super.key,
    required this.debtorName,
    required this.remainingMinor,
    required this.currency,
    this.today,
  });

  final String debtorName;
  final int remainingMinor;
  final String currency;

  /// Day used as default and as the latest choosable day (tests).
  final DateTime? today;

  @override
  State<BudgetDeclarePaymentDialog> createState() =>
      _BudgetDeclarePaymentDialogState();
}

class _BudgetDeclarePaymentDialogState
    extends State<BudgetDeclarePaymentDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: BudgetMoneyInput.plainText(widget.remainingMinor, widget.currency),
  );
  final _note = TextEditingController();
  final _otherLabel = TextEditingController();
  late final DateTime _today = DateUtils.dateOnly(
    widget.today ?? DateTime.now(),
  );
  late DateTime _paidOn = _today;
  BudgetPaymentMethod? _method;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _otherLabel.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    try {
      final value = BudgetMoneyInput.parse(_amount.text, widget.currency);
      return value <= widget.remainingMinor ? value : null;
    } on FormatException {
      return null;
    }
  }

  bool get _methodValid =>
      _method != BudgetPaymentMethod.other ||
      (_otherLabel.text.trim().isNotEmpty &&
          _otherLabel.text.trim().length <= 40);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(2000),
      lastDate: _today,
    );
    if (picked != null && mounted) setState(() => _paidOn = picked);
  }

  void _save() {
    final minor = _amountMinor;
    if (minor == null || !_methodValid) return;
    Navigator.pop(
      context,
      BudgetDeclaredPaymentResult(
        minorUnits: minor,
        paidOn: BudgetDeclaredPaymentResult.dayText(_paidOn),
        note: _note.text.trim(),
        method: _method,
        otherLabel: _method == BudgetPaymentMethod.other
            ? _otherLabel.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountValid = _amountMinor != null;
    final valid = amountValid && _methodValid;

    return AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.btPaidMarkAsPaid,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.btPaidIntro(widget.debtorName),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AmaterasuSpacing.sm),
              Text(
                l10n.btPaidRemaining(
                  BudgetMoneyFormatter.format(
                    widget.remainingMinor,
                    widget.currency,
                  ),
                ),
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('paid-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.btPaidAmount(widget.currency),
                ),
              ),
              if (!amountValid)
                Text(
                  l10n.btPaidAmountInvalid,
                  style: const TextStyle(
                    color: AmaterasuColors.accentErrorSoft,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                l10n.btPaidDate,
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
              TextButton.icon(
                key: const Key('paid-date'),
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_paidOn),
                ),
              ),
              const SizedBox(height: AmaterasuSpacing.sm),
              BudgetPaymentMethodPicker(
                method: _method,
                otherLabel: _otherLabel,
                onChanged: (value) => setState(() => _method = value),
              ),
              const SizedBox(height: AmaterasuSpacing.sm),
              TextField(
                key: const Key('paid-note'),
                controller: _note,
                maxLength: 300,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.btPaidNote),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.btActionCancel),
        ),
        FilledButton(
          key: const Key('paid-save'),
          onPressed: valid ? _save : null,
          child: Text(l10n.btPaidSave),
        ),
      ],
    );
  }
}
