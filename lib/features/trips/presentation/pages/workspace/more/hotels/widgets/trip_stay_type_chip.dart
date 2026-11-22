// Etichetta del tipo di alloggio (hotel, B&B, appartamento…) con la sua
// icona, nella stessa forma dell'etichetta di stato ma in tono neutro.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_labels.dart';

class TripStayTypeChip extends StatelessWidget {
  const TripStayTypeChip({super.key, required this.type});

  final TripStayType type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AmaterasuColors.accentBudget.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: AmaterasuColors.accentBudget.withValues(alpha: 0.45),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          TripStayLabels.typeIcon(type),
          size: 14,
          color: AmaterasuColors.accentGold,
        ),
        const SizedBox(width: 5),
        Text(
          TripStayLabels.type(type, AppLocalizations.of(context)!),
          style: const TextStyle(
            color: AmaterasuColors.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
