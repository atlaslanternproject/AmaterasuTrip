// Parte di budget_category_dashboard.dart: sezione di riepilogo
// con totali, grafici e filtri.

part of 'budget_category_dashboard.dart';

extension _BudgetCategoryDashboardStateSummary
    on _BudgetCategoryDashboardState {
  // TODO(audit): metodo unico di ~321 righe: dividerlo in widget (totali, grafici, filtri).
  Widget _summary(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String target,
    Map<String, BudgetFxQuote?> quotes,
    Map<String, String> custom,
    AppLocalizations l10n,
    bool it,
  ) {
    // Same totals as before, from the shared module (tappa 3b).
    final r = BudgetCategoryTotals.compute(
      docs,
      target,
      quotes,
      widget.api.currentUid,
    );
    final totals = r.totals;
    final excluded = r.excluded;
    final observations = r.observations;
    final total = r.total;
    final paid = r.paid;
    final converted = r.converted;
    final excludedCount = r.excludedCount;
    final myShare = r.myShare;
    final myAdvances = r.myAdvances;
    final people = r.people;
    final daily = r.daily;
    final mostRecentTitle = r.mostRecentTitle;
    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final partial = excludedCount > 0;
    final trend = BudgetTrend.from(daily);
    String categoryLabel(String key) =>
        custom[key] ?? BudgetCategoryPicker.label(key, it);
    final hasExpenses = docs.isNotEmpty;
    final visiblePrimary = converted == 0 && hasExpenses
        ? '— $target'
        : _money(_chartPersonal ? total : myShare, target);
    final visiblePaid = converted == 0 && hasExpenses
        ? '—'
        : _money(paid, target);
    final visibleRemaining = converted == 0 && hasExpenses
        ? '—'
        : _money(total - paid, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AmaterasuColors.surfaceTooltip,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AmaterasuColors.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _chartPersonal ? l10n.b6PersonalTotal : l10n.b6MyShare,
                style: const TextStyle(
                  color: _BudgetCategoryDashboardState._muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                visiblePrimary,
                style: const TextStyle(
                  color: _BudgetCategoryDashboardState._cream,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (partial)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.b6PartialTotal,
                    style: const TextStyle(
                      color: _BudgetCategoryDashboardState._gold,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: AmaterasuSpacing.sm),
              Text(
                '${l10n.b6ExpenseCount}: ${docs.length}',
                style: const TextStyle(
                  color: _BudgetCategoryDashboardState._muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (!_chartPersonal && people.isNotEmpty)
              _overviewMetric(l10n.b6GroupTotal, _money(total, target)),
            _overviewMetric(
              budgetL10n(it).btDashMyAdvances,
              converted == 0 && hasExpenses
                  ? '— $target'
                  : _money(myAdvances, target),
            ),
            _overviewMetric(l10n.b6PaidToSuppliers, visiblePaid),
            _overviewMetric(
              l10n.b6OutstandingSuppliers,
              visibleRemaining,
              accent: true,
            ),
          ],
        ),
        if (mostRecentTitle != null && mostRecentTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${l10n.b6LatestExpense}: $mostRecentTitle',
              style: const TextStyle(
                color: _BudgetCategoryDashboardState._muted,
                fontSize: 12,
              ),
            ),
          ),
        const Divider(height: 30),
        if (ordered.isEmpty)
          Text(
            l10n.b6NoExpenses,
            style: const TextStyle(color: _BudgetCategoryDashboardState._muted),
          ),
        // B8.5: real charts built from the same converted totals.
        if (ordered.isNotEmpty && total > 0) ...[
          Text(
            l10n.b85CategoryChart,
            style: const TextStyle(
              color: _BudgetCategoryDashboardState._cream,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AmaterasuSpacing.sm),
          BudgetCategoryChart(
            key: const Key('b85-category-chart'),
            values: [for (final entry in ordered) entry.value],
            labels: [for (final entry in ordered) categoryLabel(entry.key)],
            currency: target,
          ),
          const SizedBox(height: 14),
        ],
        for (final (index, entry) in ordered.indexed) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: BudgetChartPalette.at(index),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  categoryLabel(entry.key),
                  style: const TextStyle(
                    color: _BudgetCategoryDashboardState._cream,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(entry.value, target),
                style: const TextStyle(
                  color: _BudgetCategoryDashboardState._gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: AmaterasuColors.borderTrack,
              color: BudgetChartPalette.at(index),
            ),
          ),
          const SizedBox(height: 13),
        ],
        if (trend.points.isNotEmpty && total > 0) ...[
          const SizedBox(height: 10),
          Text(
            l10n.b85TrendChart,
            style: const TextStyle(
              color: _BudgetCategoryDashboardState._cream,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            trend.monthly ? l10n.b85TrendByMonth : l10n.b85TrendByDay,
            style: const TextStyle(
              color: _BudgetCategoryDashboardState._muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          BudgetTrendChart(
            key: const Key('b85-trend-chart'),
            trend: trend,
            currency: target,
          ),
        ],
        if (partial && ordered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.b85ChartsExcludeMissingRates,
              style: const TextStyle(
                color: _BudgetCategoryDashboardState._gold,
                fontSize: 12,
              ),
            ),
          ),
        if (observations.isNotEmpty) ...[
          const SizedBox(height: AmaterasuSpacing.sm),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: _BudgetCategoryDashboardState._gold,
            iconColor: _BudgetCategoryDashboardState._gold,
            title: Text(
              l10n.b6RateSource,
              style: const TextStyle(
                color: _BudgetCategoryDashboardState._muted,
                fontSize: 12,
              ),
            ),
            children: [
              for (final entry in observations.entries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      color: _BudgetCategoryDashboardState._muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.b6RateDoesNotChangeDebts,
                style: const TextStyle(
                  color: _BudgetCategoryDashboardState._muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        if (excluded.isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            l10n.b6MissingRate,
            style: const TextStyle(
              color: _BudgetCategoryDashboardState._gold,
              fontSize: 12,
            ),
          ),
          for (final entry in excluded.entries)
            Text(
              '${entry.key}: ${_money(entry.value, entry.key)}',
              style: const TextStyle(
                color: _BudgetCategoryDashboardState._gold,
                fontSize: 12,
              ),
            ),
          Text(
            '$excludedCount ${l10n.b6ExcludedCount}',
            style: const TextStyle(
              color: _BudgetCategoryDashboardState._muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
