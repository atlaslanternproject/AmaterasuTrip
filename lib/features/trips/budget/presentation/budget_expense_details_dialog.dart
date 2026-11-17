// Dialogo con i dettagli di una spesa: importi, quote, pagatori,
// stato, cambio, revisioni, rimborsi e storico.

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
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

part 'budget_expense_details_dialog_labels.dart';

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
                      budgetL10n(it).btDetailsExpenseDetails,
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AmaterasuColors.textPrimary,
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
                            ? (budgetL10n(it).btUntitledExpense)
                            : title,
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _categoryLabel(category, it),
                        style: const TextStyle(color: AmaterasuColors.textSecondary),
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
                                budgetL10n(
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
                              '${budgetL10n(it).btDetailsAccount} · ${method['accountDebitMinor'] == null ? method['accountCurrency'] : _formatMoney({'currency': method['accountCurrency'], 'minorUnits': method['accountDebitMinor']})}',
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
                            color: AmaterasuColors.accentGold,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: AmaterasuSpacing.sm),
                      Text(
                        _statusLabel(status, it),
                        style: const TextStyle(color: AmaterasuColors.textSecondary),
                      ),
                      const SizedBox(height: AmaterasuSpacing.md),
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
                          title: budgetL10n(it).btDetailsNotes,
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
                        title: budgetL10n(it).btDetailsManageExpense,
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
