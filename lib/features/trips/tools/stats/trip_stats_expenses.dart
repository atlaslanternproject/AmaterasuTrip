// Blocchi delle spese nelle Statistiche (tappa 3b): ciambella per
// categoria (BudgetCategoryChart e colori del budget, identici) con
// legenda, e spese per persona; importi già sommati dal modulo condiviso
// del budget e scritti con il suo formato.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_category_picker.dart';
import 'package:amaterasutrip/features/trips/budget/presentation/budget_charts.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stats_data.dart';

const _muted = TextStyle(color: AmaterasuColors.textMuted, fontSize: 12);
const _text = TextStyle(color: AmaterasuColors.textPrimary);

class TripStatsExpenseBlocks extends StatelessWidget {
  const TripStatsExpenseBlocks({super.key, required this.expenses});

  final TripStatsExpenses? expenses;

  Widget _row(String label, String value, {Color? dot, Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        if (dot != null) ...[
          Icon(Icons.circle, size: 10, color: dot),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(label, style: _text)),
        Text(value, style: _text),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = expenses;
    if (e == null) {
      return TripSectionBlock(
        title: l10n.statsByCategory,
        icon: Icons.donut_large_outlined,
        children: [Text(l10n.statsExpensesUnavailable, style: _text)],
      );
    }
    final it = Localizations.localeOf(context).languageCode == 'it';
    final r = e.totals;
    String money(int v) => BudgetMoneyFormatter.format(v, e.currency);
    String category(String key) =>
        e.customCategories[key] ?? BudgetCategoryPicker.label(key, it);
    final ordered = r.totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final people = r.perPerson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        TripSectionBlock(
          title: l10n.statsByCategory,
          icon: Icons.donut_large_outlined,
          children: [
            if (ordered.isEmpty)
              Text(l10n.statsNoExpenses, style: _text)
            else ...[
              BudgetCategoryChart(
                key: const Key('stats-category-chart'),
                values: [for (final c in ordered) c.value],
                labels: [for (final c in ordered) category(c.key)],
                currency: e.currency,
              ),
              const SizedBox(height: 12),
              for (final (i, c) in ordered.indexed)
                _row(
                  category(c.key),
                  money(c.value),
                  dot: BudgetChartPalette.at(i),
                  key: Key('stats-category-${c.key}'),
                ),
            ],
            if (r.excludedCount > 0)
              Text(l10n.statsPartial(r.excludedCount), style: _muted),
            const SizedBox(height: 4),
            Text(l10n.statsExpensesNote, style: _muted),
          ],
        ),
        if (people.isNotEmpty)
          TripSectionBlock(
            title: l10n.statsByPerson,
            icon: Icons.group_outlined,
            children: [
              for (final p in people)
                _row(
                  e.names[p.key] ?? '—',
                  money(p.value),
                  key: Key('stats-person-${p.key}'),
                ),
            ],
          ),
      ],
    );
  }
}
