import 'budget_expense_day.dart';
import '../calculations/budget_money_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../data/budget_fx_service.dart';
import 'budget_api.dart';
import 'budget_category_picker.dart';
import 'budget_charts.dart';
import 'budget_expense_filters.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_l10n.dart';

part 'budget_category_dashboard_rates.dart';
part 'budget_category_dashboard_widgets.dart';
part 'budget_category_dashboard_summary.dart';

/// B6: participant-scoped category totals. Shared and personal never mix.
/// All FX operations are presentation-only; original financial data is intact.
class BudgetCategoryDashboard extends StatefulWidget {
  const BudgetCategoryDashboard({
    super.key,
    required this.api,
    required this.mainCurrency,
    required this.displayCurrency,
    required this.filters,
    required this.onFiltersChanged,
  });

  final BudgetApi api;
  final String mainCurrency;
  final String displayCurrency;
  final BudgetExpenseFilters filters;
  final ValueChanged<BudgetExpenseFilters> onFiltersChanged;

  @override
  State<BudgetCategoryDashboard> createState() =>
      _BudgetCategoryDashboardState();
}

class _BudgetCategoryDashboardState extends State<BudgetCategoryDashboard> {
  static const _cream = AmaterasuColors.textPrimary;
  static const _muted = AmaterasuColors.textSecondary;
  static const _gold = AmaterasuColors.accentGold;
  static const _orange = AmaterasuColors.accentOrange;
  static const _dark = AmaterasuColors.surfaceRaised;

  final BudgetFxService _fx = BudgetFxService();
  final Set<String> _pinsRequested = {};
  late Stream<QuerySnapshot<Map<String, dynamic>>> _shared;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _private;
  late Stream<Map<String, String>> _categories;

  bool _chartPersonal = false;

  String? _cachedFxKey;
  Future<Map<String, BudgetFxQuote?>>? _cachedFx;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  @override
  void didUpdateWidget(covariant BudgetCategoryDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api.tripId != widget.api.tripId) {
      _loadStreams();
      _cachedFxKey = null;
      _pinsRequested.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final it = Localizations.localeOf(context).languageCode == 'it';
    final target = widget.displayCurrency;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _shared,
      builder: (context, shared) {
        if (shared.hasError) {
          return Text(l10n.b6LoadingError);
        }
        if (!shared.hasData) {
          return const LinearProgressIndicator();
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _private,
          builder: (context, personal) {
            if (personal.hasError) {
              return Text(l10n.b6LoadingError);
            }
            if (!personal.hasData) {
              return const LinearProgressIndicator();
            }
            return StreamBuilder<Map<String, String>>(
              stream: _categories,
              builder: (context, customResult) {
                final custom = customResult.data ?? const <String, String>{};
                final raw = _chartPersonal
                    ? personal.data!.docs
                    : shared.data!.docs;
                final docs = raw
                    .where(
                      (doc) =>
                          widget.filters.matches(doc.data(), DateTime.now()),
                    )
                    .toList();
                _pinLegacyRates(docs);
                return Card(
                  color: _dark,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AmaterasuColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AmaterasuColors.borderTrack),
                          ),
                          child: Row(
                            children: [
                              _tab(l10n.b6Group, Icons.groups_outlined, false),
                              _tab(
                                l10n.b6Personal,
                                Icons.lock_outline_rounded,
                                true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _chartPersonal
                              ? l10n.b6PersonalByCategory
                              : l10n.b6GroupByCategory,
                          style: const TextStyle(
                            color: _cream,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AmaterasuSpacing.sm),
                        Text(
                          target,
                          style: const TextStyle(color: _gold, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, BudgetFxQuote?>>(
                          future: _quoteFuture(docs, target),
                          builder: (context, rates) {
                            if (!rates.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return _summary(
                              context,
                              docs,
                              target,
                              rates.data!,
                              custom,
                              l10n,
                              it,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
