// Avviso solo informativo (non blocca nulla) con le notti del viaggio che
// nessun alloggio attivo copre, raggruppate in periodi (es. "10 apr,
// 13 apr – 15 apr"). Non appare se tutte le notti sono coperte.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_gaps.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysGapsBanner extends StatelessWidget {
  const TripStaysGapsBanner({super.key, required this.nights});

  /// Uncovered nights (see TripStaysGaps.uncoveredNights).
  final List<DateTime> nights;

  @override
  Widget build(BuildContext context) {
    if (nights.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final day = MaterialLocalizations.of(context).formatShortMonthDay;
    final periods = TripStaysGaps.ranges(nights)
        .map(
          (range) => range.$1 == range.$2
              ? day(range.$1)
              : '${day(range.$1)} – ${day(range.$2)}',
        )
        .join(', ');
    return Container(
      key: const Key('stays-gaps'),
      margin: const EdgeInsets.only(bottom: AmaterasuSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.bedtime_outlined,
            color: AmaterasuColors.accentGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.staysGapsWarning(nights.length, periods),
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.staysGapsHint,
                  style: const TextStyle(
                    color: AmaterasuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
