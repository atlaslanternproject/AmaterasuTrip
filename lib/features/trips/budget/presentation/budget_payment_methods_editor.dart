import 'package:flutter/material.dart';

import '../models/budget_payment_allocation.dart';
import 'budget_money_input.dart';

class BudgetPaymentMethodsEditor extends StatefulWidget {
  const BudgetPaymentMethodsEditor({
    super.key,
    required this.currency,
    required this.payerUid,
    required this.enabled,
    required this.onChanged,
    this.showAccount = false,
  });

  final bool showAccount;
  final String currency;
  final String payerUid;
  final bool enabled;
  final ValueChanged<List<BudgetPaymentAllocation>> onChanged;

  @override
  State<BudgetPaymentMethodsEditor> createState() =>
      _BudgetPaymentMethodsEditorState();
}

class _PaymentRow {
  final account = TextEditingController();
  final debit = TextEditingController();
  final amount = TextEditingController();
  final other = TextEditingController();
  BudgetPaymentMethod method = BudgetPaymentMethod.cash;

  void dispose() {
    account.dispose();
    debit.dispose();
    amount.dispose();
    other.dispose();
  }
}

class _BudgetPaymentMethodsEditorState
    extends State<BudgetPaymentMethodsEditor> {
  final List<_PaymentRow> _rows = [];

  void _notify() {
    final values = <BudgetPaymentAllocation>[];
    for (final row in _rows) {
      int minorUnits;
      try {
        minorUnits = BudgetMoneyInput.parse(row.amount.text, widget.currency);
      } catch (_) {
        minorUnits = 0;
      }
      final account = row.account.text.trim().toUpperCase();
      int? debit;
      if (row.debit.text.trim().isNotEmpty) {
        try {
          debit = BudgetMoneyInput.parse(row.debit.text, account);
        } on ArgumentError {
          debit = 0;
        } on FormatException {
          debit = 0;
        }
      }
      values.add(
        BudgetPaymentAllocation(
          payerUid: widget.payerUid,
          method: row.method,
          accountCurrency: account.isEmpty ? null : account,
          accountDebitMinor: debit,
          minorUnits: minorUnits,
          otherLabel: row.method == BudgetPaymentMethod.other
              ? row.other.text
              : null,
        ),
      );
    }
    widget.onChanged(values);
  }

  void _add() {
    setState(() => _rows.add(_PaymentRow()));
    _notify();
  }

  void _remove(_PaymentRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
    _notify();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final labels = <BudgetPaymentMethod, String>{
      BudgetPaymentMethod.cash: it ? 'Contanti' : 'Cash',
      BudgetPaymentMethod.card: it ? 'Carta' : 'Card',
      BudgetPaymentMethod.bankTransfer: it ? 'Bonifico' : 'Bank transfer',
      BudgetPaymentMethod.paypal: 'PayPal',
      BudgetPaymentMethod.satispay: 'Satispay',
      BudgetPaymentMethod.other: it ? 'Altro' : 'Other',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          it ? 'Metodi di pagamento' : 'Payment methods',
          style: const TextStyle(
            color: Color(0xFFF2E7D5),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          it
              ? 'Indica come hai pagato, anche usando piu metodi.'
              : 'Record how you paid, using multiple methods if needed.',
          style: const TextStyle(color: Color(0xFFB7A99B)),
        ),
        const SizedBox(height: 12),
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C211C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF49352A)),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<BudgetPaymentMethod>(
                    initialValue: row.method,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: it ? 'Metodo' : 'Method',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in labels.entries)
                        DropdownMenuItem(
                          value: item.key,
                          child: Text(item.value),
                        ),
                    ],
                    onChanged: widget.enabled
                        ? (value) {
                            if (value == null) return;
                            setState(() => row.method = value);
                            _notify();
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: row.amount,
                    enabled: widget.enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: it ? 'Importo pagato' : 'Amount paid',
                      suffixText: widget.currency,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _notify(),
                  ),
                  if (widget.showAccount) ...[
                    TextField(
                      controller: row.account,
                      enabled: widget.enabled,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: it
                            ? 'Valuta del conto (es. EUR)'
                            : 'Account currency (e.g. EUR)',
                      ),
                      onChanged: (_) => _notify(),
                    ),
                    TextField(
                      controller: row.debit,
                      enabled: widget.enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: it
                            ? 'Addebito effettivo, se noto'
                            : 'Actual account debit, if known',
                      ),
                      onChanged: (_) => _notify(),
                    ),
                  ],
                  if (row.method == BudgetPaymentMethod.other) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: row.other,
                      enabled: widget.enabled,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: it
                            ? 'Descrizione metodo'
                            : 'Method description',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _notify(),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.enabled ? () => _remove(row) : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(it ? 'Rimuovi' : 'Remove'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: widget.enabled ? _add : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(it ? 'Aggiungi metodo' : 'Add method'),
        ),
      ],
    );
  }
}
