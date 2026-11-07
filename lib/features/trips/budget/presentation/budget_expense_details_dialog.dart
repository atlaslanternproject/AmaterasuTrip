import '../calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'budget_api.dart';
import 'budget_expense_controls.dart';

class BudgetExpenseDetailsDialog extends StatelessWidget {
  const BudgetExpenseDetailsDialog({
    super.key,
    required this.expense,
    required this.expenseId,
    required this.api,
    required this.isPrivate,
  });

  final Map<String, dynamic> expense;
  final String expenseId;
  final BudgetApi api;
  final bool isPrivate;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _formatMoney(dynamic raw) {
    final money = _asMap(raw);
    final currency = money['currency']?.toString() ?? '';
    final minor = money['minorUnits'];

    if (minor is! int || currency.isEmpty) return '—';

    try {
      return BudgetMoneyFormatter.format(
        minor,
        currency,
        decimalSeparator: '.',
      );
    } catch (_) {
      return '$minor · $currency';
    }
  }

  String _categoryLabel(String value, bool it) {
    switch (value) {
      case 'accommodation':
        return it ? 'Alloggio' : 'Accommodation';
      case 'food':
        return it ? 'Cibo e ristoranti' : 'Food';
      case 'transport':
        return it ? 'Trasporti' : 'Transport';
      case 'activities':
        return it ? 'Attività' : 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return it ? 'Altro' : 'Other';
      default:
        return value.trim().isEmpty ? (it ? 'Altro' : 'Other') : value;
    }
  }

  String _statusLabel(String value, bool it) {
    switch (value) {
      case 'planned':
        return it ? 'Prevista' : 'Planned';
      case 'outstanding':
        return it ? 'Da saldare' : 'Outstanding';
      case 'paid':
        return it ? 'Pagata' : 'Paid';
      default:
        return it ? 'Non disponibile' : 'Unavailable';
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF2E7D5),
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  );

  Widget _amountRows(Map<String, dynamic> amounts, bool it) {
    if (amounts.isEmpty) {
      return Text(
        it ? 'Nessun importo registrato.' : 'No amounts recorded.',
        style: const TextStyle(color: Color(0xFFB7A99B)),
      );
    }

    final entries = amounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, String>>(
                    future: api.travelerNameMap,
                    builder: (context, result) {
                      final name = result.data?[entry.key];

                      final label = name != null && name.isNotEmpty
                          ? name
                          : result.hasError
                          ? (it ? 'Nome non disponibile' : 'Name unavailable')
                          : result.hasData
                          ? (it ? 'Viaggiatore' : 'Traveler')
                          : (it ? 'Caricamento...' : 'Loading...');

                      return Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFF2E7D5)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatMoney(entry.value),
                  style: const TextStyle(
                    color: Color(0xFFF2E7D5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _asMap(expense['snapshot']);
    final shares = _asMap(snapshot['shares']);
    final advances = _asMap(snapshot['advances']);

    final title = (expense['title']?.toString() ?? '').trim();
    final category = expense['category']?.toString() ?? 'other';
    final notes = (expense['notes']?.toString() ?? '').trim();
    final status = snapshot['status']?.toString() ?? '';

    return Dialog(
      backgroundColor: const Color(0xFF231915),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      it ? 'Dettaglio spesa' : 'Expense details',
                      style: const TextStyle(
                        color: Color(0xFFF2E7D5),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFFF2E7D5),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        title.isEmpty
                            ? (it ? 'Spesa senza titolo' : 'Untitled expense')
                            : title,
                        style: const TextStyle(
                          color: Color(0xFFF2E7D5),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _categoryLabel(category, it),
                        style: const TextStyle(color: Color(0xFFB7A99B)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _formatMoney(snapshot['total']),
                        style: const TextStyle(
                          color: Color(0xFFE3A66C),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusLabel(status, it),
                        style: const TextStyle(color: Color(0xFFB7A99B)),
                      ),
                      if (notes.isNotEmpty) ...[
                        _sectionTitle(it ? 'Note' : 'Notes'),
                        Text(
                          notes,
                          style: const TextStyle(color: Color(0xFFF2E7D5)),
                        ),
                      ],
                      _sectionTitle(l10n.budgetSplitExpense),
                      _amountRows(shares, it),
                      _sectionTitle(l10n.budgetSupplierPayments),
                      _amountRows(advances, it),
                      BudgetExpenseControls(
                        api: api,
                        expenseId: expenseId,
                        isPrivate: isPrivate,
                        expense: expense,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
