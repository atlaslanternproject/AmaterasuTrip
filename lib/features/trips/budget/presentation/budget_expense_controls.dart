import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'budget_api.dart';
import 'budget_category_edit_dialog.dart';
import 'budget_reimbursements_panel.dart';
import 'budget_revision_panel.dart';

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
        setState(
          () => _message = _it ? 'Richiesta registrata.' : 'Request recorded.',
        );
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
          title: Text(_it ? 'Conferma operazione' : 'Confirm action'),
          content: Text(
            _it
                ? 'La spesa sarà annullata solo dopo tutte le approvazioni necessarie. Lo storico sarà conservato.'
                : 'The expense will be cancelled only after required approvals. History is preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_it ? 'Annulla' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_it ? 'Conferma' : 'Confirm'),
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
      return Text(
        _it
            ? 'Spesa annullata · storico conservato'
            : 'Cancelled expense · history retained',
      );
    }

    final ref = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.api.tripId)
        .collection('budgetSharedExpenses')
        .doc(widget.expenseId)
        .collection('cancellation')
        .doc('current');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(),
        Text(
          _it ? 'Gestione spesa' : 'Expense management',
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
                ? (_it ? 'Annulla spesa personale' : 'Cancel personal expense')
                : (_it ? 'Proponi annullamento' : 'Propose cancellation'),
          ),
        ),
        if (!widget.isPrivate)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: ref.snapshots(),
            builder: (context, result) {
              final pending = result.data?.data();
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
                    _it
                        ? 'Annullamento in attesa: ${approved.length}/${required.length}'
                        : 'Pending cancellation: ${approved.length}/${required.length}',
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
                          child: Text(_it ? 'Rifiuta' : 'Reject'),
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
                          child: Text(_it ? 'Approva' : 'Approve'),
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
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _message!,
              style: const TextStyle(color: Color(0xFFE3A66C)),
            ),
          ),
      ],
    );
  }
}
