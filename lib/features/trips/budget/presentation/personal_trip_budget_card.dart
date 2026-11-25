// Card del budget personale privato: importo, valuta, speso
// e disponibile.

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'budget_expense_day.dart';
import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calculations/personal_budget_spending_calculator.dart';
import '../data/budget_fx_service.dart';
import '../data/personal_trip_budget_repository.dart';
import '../models/personal_trip_budget.dart';
import 'budget_api.dart';
import 'budget_currency_choice.dart';
import 'budget_money_input.dart';
import 'budget_display_amount.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

part 'personal_trip_budget_card_currency.dart';
part 'personal_trip_budget_card_edit.dart';
part 'personal_trip_budget_card_spending.dart';

class PersonalTripBudgetCard extends StatefulWidget {
  const PersonalTripBudgetCard({
    super.key,
    required this.api,
    required this.defaultCurrency,
    required this.displayCurrency,
    this.repository,
  });

  final BudgetApi api;
  final String defaultCurrency;
  final String displayCurrency;

  /// Defaults to the Firestore repository; replaceable in tests.
  final PersonalTripBudgetRepository? repository;

  @override
  State<PersonalTripBudgetCard> createState() => _PersonalTripBudgetCardState();
}

class _PersonalTripBudgetCardState extends State<PersonalTripBudgetCard> {
  static const _background = AmaterasuColors.surfaceRaised;
  static const _cream = AmaterasuColors.textPrimary;
  static const _muted = AmaterasuColors.textSecondary;
  static const _gold = AmaterasuColors.accentGold;
  static const _orange = AmaterasuColors.accentOrange;
  static const _red = Color(0xFFFF8A80);

  late final PersonalTripBudgetRepository _repository =
      widget.repository ?? widget.api.personalBudgetRepository;

  final BudgetFxService _fx = BudgetFxService();

  late Stream<PersonalTripBudget?> _budgetStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _sharedStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _privateStream;

  String? _cacheKey;
  Future<_SpendingResult>? _cacheFuture;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant PersonalTripBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.api.tripId != widget.api.tripId) {
      _initialize();
    }
  }

  // TODO(audit): build di ~213 righe: valutare l'estrazione delle sezioni in widget.
  @override
  Widget build(BuildContext context) {
    final it = Localizations.localeOf(context).languageCode == 'it';

    return StreamBuilder<PersonalTripBudget?>(
      stream: _budgetStream,
      builder: (context, state) {
        if (state.hasError) {
          return _panel(
            Text(
              budgetL10n(it).btPersonalBudgetLoadError,
              style: const TextStyle(color: _red),
            ),
          );
        }

        if (state.connectionState == ConnectionState.waiting) {
          return const AmaterasuLoader();
        }

        final budget = state.data;

        if (budget == null) {
          return _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budgetL10n(it).btPersonalMyTravelBudget,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AmaterasuSpacing.sm),
                Text(
                  budgetL10n(it).btPersonalSetAnOptionalPersonal,
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(budgetL10n(it).btPersonalSetBudget),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sharedStream,
          builder: (context, shared) {
            if (shared.hasError) {
              return _panel(
                Text(
                  budgetL10n(it).btUnableToLoadExpenses,
                  style: const TextStyle(color: _red),
                ),
              );
            }

            if (!shared.hasData) {
              return const AmaterasuLoader();
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _privateStream,
              builder: (context, personal) {
                if (personal.hasError) {
                  return _panel(
                    Text(
                      budgetL10n(it).btPersonalUnableToLoadPersonal,
                      style: const TextStyle(color: _red),
                    ),
                  );
                }

                if (!personal.hasData) {
                  return const AmaterasuLoader();
                }

                return FutureBuilder<_SpendingResult>(
                  future: _spending(
                    shared.data!.docs,
                    personal.data!.docs,
                    budget.currency,
                  ),
                  builder: (context, result) {
                    final spending = result.data;

                    final incomplete =
                        spending == null ||
                        spending.missing > 0 ||
                        result.hasError;

                    final remaining = spending == null
                        ? 0
                        : budget.remainingMinor(spending.spent);

                    final exceeded = !incomplete && remaining < 0;

                    return _panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: _gold,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  budgetL10n(it).btPersonalMyTravelBudget,
                                  style: const TextStyle(
                                    color: _cream,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: budgetL10n(it).btPersonalEditBudget,
                                onPressed: () => _edit(budget),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: _gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BudgetDisplayAmount(
                            minorUnits: budget.amountMinor,
                            originalCurrency: budget.currency,
                            displayCurrency: widget.displayCurrency,
                            fontSize: 26,
                          ),
                          Text(
                            budgetL10n(it).btPersonalPlannedBudget,
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: AmaterasuSpacing.md),
                          if (spending == null)
                            Text(
                              '— ${widget.displayCurrency}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 18,
                              ),
                            )
                          else
                            BudgetDisplayAmount(
                              minorUnits: spending.spent,
                              originalCurrency: budget.currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 18,
                            ),
                          Text(
                            budgetL10n(it).btPersonalYourSharePaidAnd,
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 14),
                          if (incomplete)
                            Text(
                              budgetL10n(
                                it,
                              ).btPersonalRemainingUnavailableAnAmount,
                              style: const TextStyle(color: _gold),
                            )
                          else ...[
                            Text(
                              exceeded
                                  ? (budgetL10n(it).btPersonalOverBudget)
                                  : (budgetL10n(it).btPersonalRemaining),
                              style: const TextStyle(color: _muted),
                            ),
                            BudgetDisplayAmount(
                              minorUnits: remaining.abs(),
                              originalCurrency: budget.currency,
                              displayCurrency: widget.displayCurrency,
                              fontSize: 23,
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (spending.spent / budget.amountMinor)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AmaterasuColors.borderTrack,
                                color: exceeded ? _red : _orange,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            budgetL10n(it).btPersonalPlannedExpensesAreExcluded,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
