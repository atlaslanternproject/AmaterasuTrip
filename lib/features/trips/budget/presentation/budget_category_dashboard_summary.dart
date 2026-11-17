// Parte di budget_category_dashboard.dart: sezione di riepilogo
// con totali, grafici e filtri.

part of 'budget_category_dashboard.dart';

extension _BudgetCategoryDashboardStateSummary on _BudgetCategoryDashboardState {
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
    final totals = <String, int>{};
    final excluded = <String, int>{};
    final observations = <String, String>{};
    var total = 0;
    var paid = 0;
    var converted = 0;
    var excludedCount = 0;
    var myShare = 0;
    var myAdvances = 0;
    final people = <String>{};
    final daily = <DateTime, int>{};
    String? mostRecentTitle;
    DateTime? mostRecentDate;
    for (final doc in docs) {
      final data = doc.data();
      final financial = _map(data['snapshot']);
      final amountMap = _map(financial['total']);
      final source = amountMap['currency']?.toString();
      final amount = amountMap['minorUnits'];
      if (source == null ||
          !BudgetFxService.validCurrency(source) ||
          amount is! int ||
          amount < 0) {
        continue;
      }
      final fx = quotes[doc.id];
      final value = BudgetFxService.convertMinor(amount, source, target, fx);
      if (value == null) {
        excludedCount++;
        excluded[source] = (excluded[source] ?? 0) + amount;
        continue;
      }
      converted++;
      final members = _map(financial['shares']);
      people.addAll(members.keys);
      final own = _map(members[widget.api.currentUid]);
      if (own['currency'] == source && own['minorUnits'] is int) {
        final convertedOwn = BudgetFxService.convertMinor(
          own['minorUnits'] as int,
          source,
          target,
          fx,
        );
        if (convertedOwn != null) {
          myShare += convertedOwn;
        }
      }
      final expenseTime = _createdAt(data);
      if (expenseTime != null &&
          (mostRecentDate == null || expenseTime.isAfter(mostRecentDate))) {
        mostRecentDate = expenseTime;
        mostRecentTitle = data['title']?.toString() ?? '';
      }
      if (expenseTime != null) {
        final day = DateUtils.dateOnly(expenseTime);
        daily[day] = (daily[day] ?? 0) + value;
      }
      final category = data['category']?.toString() ?? 'other';
      totals[category] = (totals[category] ?? 0) + value;
      total += value;
      var advanceTotal = 0;
      for (final item in _map(financial['advances']).values) {
        final advance = _map(item);
        if (advance['currency'] == source && advance['minorUnits'] is int) {
          advanceTotal += advance['minorUnits'] as int;
        }
      }
      final ownAdvance = _map(
        _map(financial['advances'])[widget.api.currentUid],
      );
      if (ownAdvance['currency'] == source && ownAdvance['minorUnits'] is int) {
        myAdvances +=
            BudgetFxService.convertMinor(
              ownAdvance['minorUnits'] as int,
              source,
              target,
              fx,
            ) ??
            0;
      }
      final convertedPaid = BudgetFxService.convertMinor(
        advanceTotal,
        source,
        target,
        fx,
      );
      if (convertedPaid != null) {
        paid += convertedPaid;
      }
      if (fx != null) {
        observations['$source/$target'] =
            '${fx.source} ${fx.observedIso}${fx.manual ? ' · Manual' : ''}';
      }
    }
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
                style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 13),
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
                    style: const TextStyle(color: _BudgetCategoryDashboardState._gold, fontSize: 12),
                  ),
                ),
              const SizedBox(height: AmaterasuSpacing.sm),
              Text(
                '${l10n.b6ExpenseCount}: ${docs.length}',
                style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
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
              style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
            ),
          ),
        const Divider(height: 30),
        if (ordered.isEmpty)
          Text(l10n.b6NoExpenses, style: const TextStyle(color: _BudgetCategoryDashboardState._muted)),
        // B8.5: real charts built from the same converted totals.
        if (ordered.isNotEmpty && total > 0) ...[
          Text(
            l10n.b85CategoryChart,
            style: const TextStyle(color: _BudgetCategoryDashboardState._cream, fontWeight: FontWeight.w700),
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
                style: const TextStyle(color: _BudgetCategoryDashboardState._gold),
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
            style: const TextStyle(color: _BudgetCategoryDashboardState._cream, fontWeight: FontWeight.w700),
          ),
          Text(
            trend.monthly ? l10n.b85TrendByMonth : l10n.b85TrendByDay,
            style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
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
              style: const TextStyle(color: _BudgetCategoryDashboardState._gold, fontSize: 12),
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
              style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
            ),
            children: [
              for (final entry in observations.entries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.b6RateDoesNotChangeDebts,
                style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
              ),
            ],
          ),
        ],
        if (excluded.isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            l10n.b6MissingRate,
            style: const TextStyle(color: _BudgetCategoryDashboardState._gold, fontSize: 12),
          ),
          for (final entry in excluded.entries)
            Text(
              '${entry.key}: ${_money(entry.value, entry.key)}',
              style: const TextStyle(color: _BudgetCategoryDashboardState._gold, fontSize: 12),
            ),
          Text(
            '$excludedCount ${l10n.b6ExcludedCount}',
            style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
