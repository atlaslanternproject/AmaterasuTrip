part of 'budget_charts.dart';

/// Bar chart of the spending over time.
class BudgetTrendChart extends StatelessWidget {
  const BudgetTrendChart({
    super.key,
    required this.trend,
    required this.currency,
  });

  final BudgetTrend trend;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final points = trend.points;
    if (points.isEmpty) return const SizedBox.shrink();
    final label = trend.monthly
        ? intl.DateFormat.yMMM(locale).format
        : intl.DateFormat.MMMd(locale).format;
    final maxValue = points.fold<int>(
      0,
      (max, point) => point.minorUnits > max ? point.minorUnits : max,
    );
    // Show about six labels, whatever the number of bars.
    final every = (points.length / 6).ceil().clamp(1, points.length);
    final description = [
      for (final point in points)
        if (point.minorUnits > 0)
          '${label(point.period)} ${_money(point.minorUnits, currency)}',
    ].join(', ');

    return Semantics(
      label: l10n.b85ChartSemantics(description),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 320.0;
          final barWidth = (width / points.length * 0.55).clamp(3.0, 22.0);
          return SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxValue == 0 ? 1 : maxValue * 1.15,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => BudgetChartPalette.tooltip,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${label(points[group.x].period)}\n'
                          '${_money(points[group.x].minorUnits, currency)}',
                          const TextStyle(
                            color: BudgetChartPalette.cream,
                            fontSize: 12,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= points.length ||
                            index % every != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            label(points[index].period),
                            style: const TextStyle(
                              color: BudgetChartPalette.muted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].minorUnits.toDouble(),
                          width: barWidth,
                          color: BudgetChartPalette.at(0),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
