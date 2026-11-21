// Avviso (non blocca nulla) quando due alloggi attivi si sovrappongono
// nelle date: una riga per ogni coppia.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysOverlapBanner extends StatelessWidget {
  const TripStaysOverlapBanner({super.key, required this.pairs});

  final List<(TripStay, TripStay)> pairs;

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('stays-overlap'),
      margin: const EdgeInsets.only(bottom: AmaterasuSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AmaterasuColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AmaterasuColors.accentGold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AmaterasuColors.accentGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (first, second) in pairs)
                  Text(
                    l10n.staysOverlapWarning(first.name, second.name),
                    style: const TextStyle(
                      color: AmaterasuColors.textPrimary,
                      fontSize: 13,
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
