// Grafici del budget: tavolozza colori e grafico per categoria.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:amaterasutrip/l10n/app_localizations.dart';

import '../calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

part 'budget_charts_data.dart';
part 'budget_charts_trend.dart';

/// Colors of the charts, taken from the warm palette already used by the
/// budget screens, in an order that keeps neighbours distinguishable.
abstract final class BudgetChartPalette {
  static const colors = <Color>[
    AmaterasuColors.accentOrange,
    AmaterasuColors.accentGold,
    AmaterasuColors.accentBudget,
    AmaterasuColors.textPrimary,
    AmaterasuColors.accentSettings,
    AmaterasuColors.textMuted,
    AmaterasuColors.accentFlame,
    AmaterasuColors.textSecondary,
  ];

  static Color at(int index) => colors[index % colors.length];

  static const track = AmaterasuColors.borderTrack;
  static const muted = AmaterasuColors.textSecondary;
  static const cream = AmaterasuColors.textPrimary;
  static const tooltip = AmaterasuColors.surfaceTooltip;
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
