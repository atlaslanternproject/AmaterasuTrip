// Pannello dei rimborsi: debiti tra viaggiatori, richieste,
// conferme, rifiuti e chiusura dei debiti.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../calculations/budget_money_formatter.dart';
import '../calculations/budget_snapshot_debts.dart';
import '../models/budget_payment_allocation.dart';
import 'budget_payment_methods_editor.dart';
import 'budget_api.dart';
import 'budget_display_amount.dart';
import 'budget_people.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

part 'budget_reimbursements_panel_data.dart';
part 'budget_reimbursements_panel_actions.dart';
part 'budget_reimbursements_panel_request.dart';
part 'budget_reimbursements_panel_close_debt_dialog.dart';

class BudgetReimbursementsPanel extends StatefulWidget {
  const BudgetReimbursementsPanel({
    super.key,
    required this.api,
    required this.expenseId,
    required this.expense,
    required this.displayCurrency,
  });

  final BudgetApi api;
  final String expenseId;
  final Map<String, dynamic> expense;
  final String displayCurrency;

  @override
  State<BudgetReimbursementsPanel> createState() =>
      _BudgetReimbursementsPanelState();
}

typedef _DebtRow = BudgetPairDebt;

class _BudgetReimbursementsPanelState extends State<BudgetReimbursementsPanel> {
  bool _busy = false;
  String? _message;

  late final Future<Map<String, String>> _names = _loadNames();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _refunds = widget.api
      .reimbursements(widget.expenseId);

  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  bool get _it => Localizations.localeOf(context).languageCode == 'it';

  // TODO(audit): build di ~394 righe: estrarre sezioni in widget dedicati (stesso aspetto).
  @override
  Widget build(BuildContext context) {
    if (widget.expense['lifecycle'] == 'cancelled') {
      return const SizedBox.shrink();
    }

    final snapshot = _map(widget.expense['snapshot']);

    if (snapshot['status'] != 'paid') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          budgetL10n(_it).btRefundsDebtsBetweenTravelersBecome,
          style: const TextStyle(color: AmaterasuColors.textSecondary),
        ),
      );
    }

    final total = _map(snapshot['total']);
    final currency = total['currency']?.toString() ?? 'EUR';
    final debts = _buildDebts(snapshot);

    return FutureBuilder<Map<String, String>>(
      future: _names,
      builder: (context, namesSnapshot) {
        if (namesSnapshot.hasError) {
          return Text(budgetL10n(_it).btRefundsUnableToLoadTraveler);
        }

        if (!namesSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final names = namesSnapshot.data!;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _refunds,
          builder: (context, refundsSnapshot) {
            if (refundsSnapshot.hasError) {
              return Text(budgetL10n(_it).btRefundsUnableToLoadReimbursements);
            }

            if (!refundsSnapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final docs = refundsSnapshot.data!.docs;

            final pendingForCurrentUser = docs.where((doc) {
              final data = doc.data();
              return data['status'] == 'pending' &&
                  data['creditorUid'] == widget.api.currentUid;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Divider(),
                Text(
                  budgetL10n(_it).btRefundsDebtsAndReimbursements,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  budgetL10n(_it).btRefundsWhoOwesMoneyCan,
                  style: const TextStyle(
                    color: AmaterasuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                if (pendingForCurrentUser.isNotEmpty) ...[
                  Text(
                    budgetL10n(_it).btRefundsRequestsWaitingForYour,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AmaterasuSpacing.sm),
                  for (final doc in pendingForCurrentUser) ...[
                    Builder(
                      builder: (context) {
                        final data = doc.data();
                        final debtorUid = data['debtorUid']?.toString() ?? '';
                        final creditorUid =
                            data['creditorUid']?.toString() ?? '';
                        final minorUnits = data['minorUnits'] is int
                            ? data['minorUnits'] as int
                            : 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_name(debtorUid, names)} → ${_name(creditorUid, names)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 16,
                              ),
                              const SizedBox(height: 5),
                              for (final field in ['createdAt', 'decidedAt'])
                                if (data[field] is Timestamp)
                                  Text(
                                    '${field == "createdAt" ? (budgetL10n(_it).btRefundsRequested) : (budgetL10n(_it).btRefundsDecision)} · ${MaterialLocalizations.of(context).formatMediumDate((data[field] as Timestamp).toDate())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime((data[field] as Timestamp).toDate()))}',
                                  ),
                              if (data['decidedByUid'] is String)
                                Text(
                                  '${budgetL10n(_it).btRefundsDecidedBy} ${_name(data['decidedByUid'] as String, names)}',
                                ),
                              _paymentDetails(data, currency),
                              const SizedBox(height: AmaterasuSpacing.sm),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmReimbursement(
                                            doc.id,
                                            false,
                                          ),
                                    child: Text(budgetL10n(_it).btActionReject),
                                  ),
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmReimbursement(
                                            doc.id,
                                            true,
                                          ),
                                    child: Text(budgetL10n(_it).btActionConfirm),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const Divider(),
                ],

                for (final debt in debts) ...[
                  Builder(
                    builder: (context) {
                      final confirmed = _sumStatus(
                        docs,
                        debt.debtorUid,
                        debt.creditorUid,
                        {'confirmed'},
                      );
                      final closed = _sumStatus(
                        docs,
                        debt.debtorUid,
                        debt.creditorUid,
                        {BudgetSnapshotDebts.writtenOff},
                      );
                      final pending = _sumStatus(
                        docs,
                        debt.debtorUid,
                        debt.creditorUid,
                        {'pending'},
                      );
                      final l10n = AppLocalizations.of(context)!;
                      final remaining = debt.minorUnits - confirmed - closed;
                      final availableToDeclare = remaining - pending;
                      final isDebtor = widget.api.currentUid == debt.debtorUid;
                      final isCreditor =
                          widget.api.currentUid == debt.creditorUid;
                      // B8.6: debts involving a former traveler are
                      // read-only; only the creditor may close them.
                      final active = names.keys.toSet();
                      final formerDebtor = BudgetPeople.isFormer(
                        debt.debtorUid,
                        active,
                      );
                      final involvesFormer =
                          formerDebtor ||
                          BudgetPeople.isFormer(debt.creditorUid, active);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_name(debt.debtorUid, names)} → ${_name(debt.creditorUid, names)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(budgetL10n(_it).btRefundsOutstanding),
                            const SizedBox(height: 3),
                            BudgetDisplayAmount(
                              expense: widget.expense,
                              minorUnits: remaining,
                              originalCurrency: currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 17,
                            ),
                            if (confirmed > 0) ...[
                              const SizedBox(height: AmaterasuSpacing.sm),
                              Text(budgetL10n(_it).btRefundsConfirmed),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: confirmed,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ],
                            if (closed > 0) ...[
                              const SizedBox(height: AmaterasuSpacing.sm),
                              Text(l10n.b86Closed),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: closed,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ],
                            if (pending > 0) ...[
                              const SizedBox(height: AmaterasuSpacing.sm),
                              Text(budgetL10n(_it).btRefundsPendingConfirmation),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: pending,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                            ],
                            if (involvesFormer && remaining > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  l10n.b86ReadOnlyFormer,
                                  style: const TextStyle(
                                    color: AmaterasuColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (isCreditor &&
                                formerDebtor &&
                                remaining > 0 &&
                                pending == 0)
                              TextButton.icon(
                                key: Key('b86-close-${debt.debtorUid}'),
                                onPressed: _busy
                                    ? null
                                    : () => _closeDebt(
                                        debt,
                                        _name(debt.debtorUid, names),
                                      ),
                                icon: const Icon(Icons.task_alt_outlined),
                                label: Text(l10n.b86CloseDebt),
                              ),
                            if (isDebtor &&
                                !involvesFormer &&
                                availableToDeclare > 0)
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _requestReimbursement(
                                        debt,
                                        availableToDeclare,
                                        currency,
                                        _name(debt.creditorUid, names),
                                      ),
                                icon: const Icon(Icons.payments_outlined),
                                label: Text(
                                  budgetL10n(_it).btRefundsReportAReimbursement,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (docs.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    budgetL10n(_it).btRefundsReimbursementHistory,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AmaterasuSpacing.sm),
                  for (final doc in docs) ...[
                    Builder(
                      builder: (context) {
                        final data = doc.data();
                        final debtorUid = data['debtorUid']?.toString() ?? '';
                        final creditorUid =
                            data['creditorUid']?.toString() ?? '';
                        final minorUnits = data['minorUnits'] is int
                            ? data['minorUnits'] as int
                            : 0;
                        final status = data['status']?.toString() ?? 'pending';

                        String label;
                        switch (status) {
                          case 'confirmed':
                            label = budgetL10n(_it).btRefundsConfirmed;
                            break;
                          case 'rejected':
                            label = budgetL10n(_it).btRefundsRejected;
                            break;
                          case BudgetSnapshotDebts.writtenOff:
                            label = AppLocalizations.of(context)!.b86Closed;
                            break;
                          default:
                            label = budgetL10n(_it).btRefundsPending;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_name(debtorUid, names)} → ${_name(creditorUid, names)} · $label',
                                style: const TextStyle(
                                  color: AmaterasuColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AmaterasuSpacing.xs),
                              BudgetDisplayAmount(
                                expense: widget.expense,
                                minorUnits: minorUnits,
                                originalCurrency: currency,
                                displayCurrency: widget.displayCurrency,
                                fontSize: 15,
                              ),
                              const SizedBox(height: 5),
                              if (status == BudgetSnapshotDebts.writtenOff) ...[
                                if (data['decidedByUid'] is String)
                                  Text(
                                    AppLocalizations.of(context)!.b86ClosedBy(
                                      _name(
                                        data['decidedByUid'] as String,
                                        names,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (data['reason'] is String)
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.b86Reason(data['reason'] as String),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ] else
                                _paymentDetails(data, currency),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],

                if (_busy) const LinearProgressIndicator(),
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
          },
        );
      },
    );
  }
}

