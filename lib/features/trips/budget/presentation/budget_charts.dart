import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/budget_money_formatter.dart';

/// Colors of the charts, taken from the warm palette already used by the
/// budget screens, in an order that keeps neighbours distinguishable.
abstract final class BudgetChartPalette {
  static const colors = <Color>[
    Color(0xFFE17A43),
    Color(0xFFE3A66C),
    Color(0xFFD96C32),
    Color(0xFFF2E7D5),
    Color(0xFFE28A32),
    Color(0xFF9E9287),
    Color(0xFFE86A3A),
    Color(0xFFB7A99B),
  ];

  static Color at(int index) => colors[index % colors.length];

  static const track = Color(0xFF49312B);
  static const muted = Color(0xFFB7A99B);
  static const cream = Color(0xFFF2E7D5);
  static const tooltip = Color(0xFF30231E);
}

/// One bar of the trend chart.
class BudgetTrendPoint {
  const BudgetTrendPoint(this.period, this.minorUnits);

  final DateTime period;
  final int minorUnits;

  @override
  bool operator ==(Object other) =>
      other is BudgetTrendPoint &&
      other.period == period &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(period, minorUnits);

  @override
  String toString() => '${period.toIso8601String()}=$minorUnits';
}

/// Trend data, grouped by day for short trips and by month otherwise.
class BudgetTrend {
  const BudgetTrend(this.points, {required this.monthly});

  /// Up to this many days the chart shows one bar per day.
  static const maxDailySpan = 45;

  final List<BudgetTrendPoint> points;
  final bool monthly;

  /// [amounts] are expense amounts by day, already in the display
  /// currency. Empty days in between are kept, so time reads correctly.
  factory BudgetTrend.from(Map<DateTime, int> amounts) {
    if (amounts.isEmpty) return const BudgetTrend([], monthly: false);
    final days = <DateTime, int>{};
    for (final entry in amounts.entries) {
      final day = DateTime(entry.key.year, entry.key.month, entry.key.day);
      days[day] = (days[day] ?? 0) + entry.value;
    }
    final sorted = days.keys.toList()..sort();
    final first = sorted.first;
    final last = sorted.last;
    final span = DateTime.utc(
      last.year,
      last.month,
      last.day,
    ).difference(DateTime.utc(first.year, first.month, first.day)).inDays;

    if (span < maxDailySpan) {
      return BudgetTrend([
        for (var i = 0; i <= span; i++)
          () {
            final day = DateTime(first.year, first.month, first.day + i);
            return BudgetTrendPoint(day, days[day] ?? 0);
          }(),
      ], monthly: false);
    }

    final months = <DateTime, int>{};
    for (final entry in days.entries) {
      final month = DateTime(entry.key.year, entry.key.month);
      months[month] = (months[month] ?? 0) + entry.value;
    }
    final points = <BudgetTrendPoint>[];
    var month = DateTime(first.year, first.month);
    final end = DateTime(last.year, last.month);
    while (!month.isAfter(end)) {
      points.add(BudgetTrendPoint(month, months[month] ?? 0));
      month = DateTime(month.year, month.month + 1);
    }
    return BudgetTrend(points, monthly: true);
  }
}

String _money(int minor, String currency) {
  try {
    return BudgetMoneyFormatter.format(minor, currency);
  } on ArgumentError {
    return '$minor $currency';
  }
}

/// Donut chart of the category totals. The legend is the category list
/// shown under it by the dashboard, with the same colors.
class BudgetCategoryChart extends StatelessWidget {
  const BudgetCategoryChart({
    super.key,
    required this.values,
    required this.labels,
    required this.currency,
  });

  /// Category totals, largest first.
  final List<int> values;
  final List<String> labels;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return const SizedBox.shrink();
    final description = [
      for (var i = 0; i < values.length; i++)
        '${labels[i]} ${(values[i] * 100 / total).round()}%',
    ].join(', ');
    return Semantics(
      label: l10n.b85ChartSemantics(description),
      child: SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: values.length > 1 ? 2 : 0,
                centerSpaceRadius: 58,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: false),
                sections: [
                  for (var i = 0; i < values.length; i++)
                    PieChartSectionData(
                      value: values[i].toDouble(),
                      color: BudgetChartPalette.at(i),
                      radius: 30,
                      showTitle: false,
                    ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 104),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _money(total, currency),
                  style: const TextStyle(
                    color: BudgetChartPalette.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
