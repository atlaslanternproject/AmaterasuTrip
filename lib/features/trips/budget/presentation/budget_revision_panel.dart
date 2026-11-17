import 'budget_money_input.dart';
import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'budget_api.dart';
import 'budget_people.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

part 'budget_revision_panel_actions.dart';
part 'budget_revision_panel_edit.dart';

class BudgetRevisionPanel extends StatefulWidget {
  const BudgetRevisionPanel({
    super.key,
    required this.api,
    required this.expenseId,
    required this.expense,
  });

  final BudgetApi api;
  final String expenseId;
  final Map<String, dynamic> expense;

  @override
  State<BudgetRevisionPanel> createState() => _BudgetRevisionPanelState();
}

class _BudgetRevisionPanelState extends State<BudgetRevisionPanel> {
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  bool _busy = false;
  String? _feedback;
  late Future<Map<String, String>> _names;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _proposals = widget.api
      .proposals(widget.expenseId);

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reimbursements =
      widget.api.reimbursements(widget.expenseId);

  @override
  void initState() {
    super.initState();
    _names = widget.api.travelerNameMap;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.expense['lifecycle'] == 'cancelled') {
      return const SizedBox.shrink();
    }

    final creator = widget.expense['createdByUid']?.toString();

    final canPropose = creator == widget.api.currentUid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _proposals,
      builder: (context, proposalResult) {
        if (proposalResult.hasError) {
          return Text(l10n.budgetRevisionLoadError);
        }

        if (!proposalResult.hasData) {
          return const LinearProgressIndicator();
        }

        final pending = proposalResult.data!.docs
            .where((doc) => doc.data()['state'] == 'pending')
            .toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reimbursements,
          builder: (context, reimbursementResult) {
            if (reimbursementResult.hasError) {
              return Text(l10n.budgetRevisionLoadError);
            }

            if (!reimbursementResult.hasData) {
              return const LinearProgressIndicator();
            }

            final hasReimbursements = reimbursementResult.data!.docs.isNotEmpty;

            final canEdit = canPropose && pending.isEmpty && !hasReimbursements;

            return FutureBuilder<Map<String, String>>(
              future: _names,
              builder: (context, namesResult) {
                if (namesResult.hasError) {
                  return Text(l10n.budgetNamesUnavailable);
                }

                if (!namesResult.hasData) {
                  return const LinearProgressIndicator();
                }

                final names = namesResult.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Divider(),
                    Text(
                      l10n.budgetRevisionSection,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.sm),

                    if (canPropose)
                      OutlinedButton.icon(
                        onPressed: canEdit && !_busy
                            ? () => _edit(names)
                            : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.budgetRevisionEdit),
                      ),

                    if (canPropose && hasReimbursements)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.budgetRevisionLocked,
                          style: const TextStyle(color: AmaterasuColors.textSecondary),
                        ),
                      ),

                    for (final doc in pending) ...[
                      Builder(
                        builder: (context) {
                          final data = doc.data();

                          final required = List<String>.from(
                            data['requiredUids'] as List? ?? [],
                          );

                          final approved = List<String>.from(
                            data['approvedUids'] as List? ?? [],
                          );

                          final currentUid = widget.api.currentUid;

                          final canVote =
                              required.contains(currentUid) &&
                              !approved.contains(currentUid);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.budgetRevisionPending,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AmaterasuSpacing.xs),
                              Text('${approved.length}/${required.length}'),
                              const SizedBox(height: 6),
                              for (final person in required)
                                Text(
                                  '${names[person] ?? BudgetPeople.recorded(widget.expense)[person] ?? l10n.b86FormerTraveler}: '
                                  '${approved.contains(person) ? l10n.budgetRevisionApproved : l10n.budgetRevisionWaiting}',
                                ),
                              if (canVote)
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(doc.id, false),
                                      child: Text(l10n.budgetRevisionReject),
                                    ),
                                    FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decide(doc.id, true),
                                      child: Text(l10n.budgetRevisionApprove),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    ],

                    if (_busy) const LinearProgressIndicator(),

                    if (_feedback != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _feedback!,
                          style: const TextStyle(color: AmaterasuColors.accentGold),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
