// Comandi di gestione di una spesa: richiesta di annullamento,
// decisione e annullamento delle spese personali.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'budget_api.dart';
import 'budget_category_edit_dialog.dart';
import 'budget_reimbursements_panel.dart';
import 'budget_revision_panel.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

class BudgetExpenseControls extends StatefulWidget {
  const BudgetExpenseControls({
    super.key,
    required this.api,
    required this.expenseId,
    required this.isPrivate,
    required this.expense,
    required this.displayCurrency,
  });

  final BudgetApi api;
  final String expenseId;
  final bool isPrivate;
  final Map<String, dynamic> expense;
  final String displayCurrency;

  @override
  State<BudgetExpenseControls> createState() => _BudgetExpenseControlsState();
}

class _BudgetExpenseControlsState extends State<BudgetExpenseControls> {
  bool _busy = false;
  String? _message;
  bool get _it => Localizations.localeOf(context).languageCode == 'it';

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _message = budgetL10n(_it).btControlsRequestRecorded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(budgetL10n(_it).btControlsConfirmAction),
          content: Text(budgetL10n(_it).btControlsTheExpenseWillBe),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(budgetL10n(_it).btActionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(budgetL10n(_it).btActionConfirm),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final data = widget.expense;
    final cancelled = data['lifecycle'] == 'cancelled';
    if (cancelled) {
      return Text(budgetL10n(_it).btControlsCancelledExpenseHistoryRetained);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(),
        Text(
          budgetL10n(_it).btControlsExpenseManagement,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (data['createdByUid'] == widget.api.currentUid)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (_) => BudgetCategoryEditDialog(
                        api: widget.api,
                        expenseId: widget.expenseId,
                        private: widget.isPrivate,
                        initialCategory:
                            data['category']?.toString() ?? 'other',
                      ),
                    );
                  },
            icon: const Icon(Icons.category_outlined),
            label: Text(AppLocalizations.of(context)!.b6EditCategory),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  if (!await _confirm()) {
                    return;
                  }
                  await _perform(
                    () => widget.isPrivate
                        ? widget.api.cancelPrivate(widget.expenseId)
                        : widget.api.requestCancellation(widget.expenseId),
                  );
                },
          icon: const Icon(Icons.delete_outline),
          label: Text(
            widget.isPrivate
                ? (budgetL10n(_it).btControlsCancelPersonalExpense)
                : (budgetL10n(_it).btControlsProposeCancellation),
          ),
        ),
        if (!widget.isPrivate)
          StreamBuilder<Map<String, dynamic>?>(
            stream: widget.api.cancellationRequest(widget.expenseId),
            builder: (context, result) {
              final pending = result.data;
              if (pending == null || pending['state'] != 'pending') {
                return const SizedBox.shrink();
              }
              final required = List<String>.from(
                pending['requiredUids'] as List? ?? [],
              );
              final approved = List<String>.from(
                pending['approvedUids'] as List? ?? [],
              );
              final canVote =
                  required.contains(widget.api.currentUid) &&
                  !approved.contains(widget.api.currentUid);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budgetL10n(_it).btControlsPendingCancellation(
                      approved.length,
                      required.length,
                    ),
                  ),
                  if (canVote)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _perform(
                                  () => widget.api.decideCancellation(
                                    widget.expenseId,
                                    false,
                                  ),
                                ),
                          child: Text(budgetL10n(_it).btActionReject),
                        ),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _perform(
                                  () => widget.api.decideCancellation(
                                    widget.expenseId,
                                    true,
                                  ),
                                ),
                          child: Text(budgetL10n(_it).btControlsApprove),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        if (!widget.isPrivate)
          BudgetRevisionPanel(
            api: widget.api,
            expenseId: widget.expenseId,
            expense: widget.expense,
          ),
        if (!widget.isPrivate)
          BudgetReimbursementsPanel(
            api: widget.api,
            expenseId: widget.expenseId,
            expense: widget.expense,
            displayCurrency: widget.displayCurrency,
          ),
        if (_busy) const AmaterasuLoader(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _message!,
              style: const TextStyle(color: AmaterasuColors.accentGold),
            ),
          ),
      ],
    );
  }
}
