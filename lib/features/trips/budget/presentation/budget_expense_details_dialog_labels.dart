// Parte di budget_expense_details_dialog.dart: etichette
// di categoria e stato e righe degli importi.

part of 'budget_expense_details_dialog.dart';

extension _BudgetExpenseDetailsDialogLabels on BudgetExpenseDetailsDialog {
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
        return budgetL10n(it).btCatAccommodation;
      case 'food':
        return budgetL10n(it).btDetailsFood;
      case 'transport':
        return budgetL10n(it).btCatTransport;
      case 'activities':
        return budgetL10n(it).btCatActivities;
      case 'shopping':
        return 'Shopping';
      case 'other':
        return budgetL10n(it).btCatOther;
      default:
        return value.trim().isEmpty ? (budgetL10n(it).btCatOther) : value;
    }
  }

  String _statusLabel(String value, bool it) {
    switch (value) {
      case 'planned':
        return budgetL10n(it).btStatusPlanned;
      case 'outstanding':
        return budgetL10n(it).btStatusOutstanding;
      case 'paid':
        return budgetL10n(it).btStatusPaid;
      default:
        return budgetL10n(it).btDetailsUnavailable;
    }
  }

  Widget _amountRows(Map<String, dynamic> amounts, bool it) {
    if (amounts.isEmpty) {
      return Text(
        budgetL10n(it).btDetailsNoAmountsRecorded,
        style: const TextStyle(color: AmaterasuColors.textSecondary),
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
                      final name =
                          result.data?[entry.key] ??
                          BudgetPeople.recorded(expense)[entry.key];

                      final label = name != null && name.isNotEmpty
                          ? name
                          : result.hasError
                          ? (budgetL10n(it).btDetailsNameUnavailable)
                          : result.hasData
                          ? AppLocalizations.of(context)!.b86FormerTraveler
                          : (budgetL10n(it).btDetailsLoading);

                      return Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatMoney(entry.value),
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
