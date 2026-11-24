// Avanzamento di una checklist o di una sua categoria: barra arancio e
// scritta "12 su 30 · 40%".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripChecklistProgress extends StatelessWidget {
  const TripChecklistProgress({
    super.key,
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: AmaterasuColors.accentBudget,
            backgroundColor: AmaterasuColors.borderWarm,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.checklistProgress(done, total, (value * 100).round()),
          style: const TextStyle(
            color: AmaterasuColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
