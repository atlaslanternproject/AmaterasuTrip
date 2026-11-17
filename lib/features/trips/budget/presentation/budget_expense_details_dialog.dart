import '../calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'budget_dialog_chrome.dart';
import 'budget_expense_day.dart';
import 'budget_expense_history.dart';
import 'budget_fx_manual_dialog.dart';
import 'budget_display_amount.dart';
import 'budget_api.dart';
import 'budget_expense_controls.dart';
import 'budget_people.dart';

class BudgetExpenseDetailsDialog extends StatelessWidget {
  const BudgetExpenseDetailsDialog({
    super.key,
    required this.expense,
    required this.expenseId,
    required this.api,
    required this.isPrivate,
    this.displayCurrency,
  });

  final Map<String, dynamic> expense;
  final String expenseId;
  final BudgetApi api;
  final bool isPrivate;
  final String? displayCurrency;

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
        return _l10n(it).btDetailsAccommodation;
      case 'food':
        return _l10n(it).btDetailsFood;
      case 'transport':
        return _l10n(it).btDetailsTransport;
      case 'activities':
        return _l10n(it).btDetailsActivities;
      case 'shopping':
        return 'Shopping';
      case 'other':
        return _l10n(it).btDetailsOther;
      default:
        return value.trim().isEmpty ? (_l10n(it).btDetailsOther) : value;
    }
  }

  String _statusLabel(String value, bool it) {
    switch (value) {
      case 'planned':
        return _l10n(it).btDetailsPlanned;
      case 'outstanding':
        return _l10n(it).btDetailsOutstanding;
      case 'paid':
        return _l10n(it).btDetailsPaid;
      default:
        return _l10n(it).btDetailsUnavailable;
    }
  }

  Widget _amountRows(Map<String, dynamic> amounts, bool it) {
    if (amounts.isEmpty) {
      return Text(
        _l10n(it).btDetailsNoAmountsRecorded,
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
                      final name =
                          result.data?[entry.key] ??
                          BudgetPeople.recorded(expense)[entry.key];

                      final label = name != null && name.isNotEmpty
                          ? name
                          : result.hasError
                          ? (_l10n(it).btDetailsNameUnavailable)
                          : result.hasData
                          ? AppLocalizations.of(context)!.b86FormerTraveler
                          : (_l10n(it).btDetailsLoading);

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
    final totalMoney = _asMap(snapshot['total']);
    final originalMinor = totalMoney['minorUnits'];
    final originalCurrency = totalMoney['currency']?.toString() ?? '';
    final shares = _asMap(snapshot['shares']);
    final advances = _asMap(snapshot['advances']);

    final title = (expense['title']?.toString() ?? '').trim();
    final category = expense['category']?.toString() ?? 'other';
    final day = budgetExpenseDay(expense);
    final methods = expense['accountPayments'];
    final notes = (expense['notes']?.toString() ?? '').trim();
    final status = snapshot['status']?.toString() ?? '';

    return Dialog(
      backgroundColor: BudgetDialogChrome.background,
      shape: BudgetDialogChrome.shape,
      insetPadding: BudgetDialogChrome.insetPadding,
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
                      _l10n(it).btDetailsExpenseDetails,
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
                            ? (_l10n(it).btDetailsUntitledExpense)
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
                      if (day != null)
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(day),
                        ),
                      if (expense['createdByUid'] == api.currentUid)
                        FutureBuilder<String>(
                          future: api.tripCurrency(),
                          builder: (context, result) {
                            final target = result.data;
                            if (target == null || target == originalCurrency) {
                              return const SizedBox.shrink();
                            }
                            return TextButton.icon(
                              icon: const Icon(Icons.currency_exchange),
                              label: Text(
                                _l10n(
                                  it,
                                ).btDetailsAdjustRate(originalCurrency, target),
                              ),
                              onPressed: () async {
                                final saved = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => BudgetFxManualDialog(
                                    api: api,
                                    expenseId: expenseId,
                                    private: isPrivate,
                                    from: originalCurrency,
                                    to: target,
                                  ),
                                );
                                if (context.mounted && saved == true) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                      if (methods is List)
                        for (final method in methods.whereType<Map>())
                          if (method['accountCurrency'] is String)
                            Text(
                              '${_l10n(it).btDetailsAccount} · ${method['accountDebitMinor'] == null ? method['accountCurrency'] : _formatMoney({'currency': method['accountCurrency'], 'minorUnits': method['accountDebitMinor']})}',
                            ),
                      if (originalMinor is int && originalCurrency.isNotEmpty)
                        BudgetDisplayAmount(
                          expense: expense,
                          minorUnits: originalMinor,
                          originalCurrency: originalCurrency,
                          displayCurrency: displayCurrency ?? originalCurrency,
                          fontSize: 30,
                        )
                      else
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
                      const SizedBox(height: 16),
                      BudgetDialogChrome.section(
                        title: l10n.budgetSplitExpense,
                        icon: Icons.groups_outlined,
                        children: [_amountRows(shares, it)],
                      ),
                      BudgetDialogChrome.section(
                        title: l10n.budgetSupplierPayments,
                        icon: Icons.account_balance_wallet_outlined,
                        children: [_amountRows(advances, it)],
                      ),
                      BudgetExpenseHistory(
                        api: api,
                        expenseId: expenseId,
                        private: isPrivate,
                        expense: expense,
                      ),
                      if (notes.isNotEmpty)
                        BudgetDialogChrome.section(
                          title: _l10n(it).btDetailsNotes,
                          icon: Icons.notes_rounded,
                          children: [
                            Text(
                              notes,
                              style: const TextStyle(
                                color: BudgetDialogChrome.cream,
                              ),
                            ),
                          ],
                        ),
                      BudgetDialogChrome.section(
                        title: _l10n(it).btDetailsManageExpense,
                        icon: Icons.settings_outlined,
                        children: [
                          BudgetExpenseControls(
                            api: api,
                            expenseId: expenseId,
                            isPrivate: isPrivate,
                            expense: expense,
                            displayCurrency:
                                displayCurrency ?? originalCurrency,
                          ),
                        ],
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

/// Texts of this screen, in the language chosen by the existing `it` flag.
AppLocalizations _l10n(bool it) =>
    lookupAppLocalizations(Locale(it ? 'it' : 'en'));
