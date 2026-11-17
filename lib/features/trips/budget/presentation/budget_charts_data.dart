// Parte di budget_charts.dart: dati dell'andamento delle spese nel tempo.

part of 'budget_charts.dart';

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
