// Etichetta colorata dello stato di un soggiorno (prenotato, da confermare,
// annullato), nello stile delle etichette di stato del resto dell'app.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_labels.dart';

class TripStayStatusChip extends StatelessWidget {
  const TripStayStatusChip({super.key, required this.status});

  final TripStayStatus status;

  @override
  Widget build(BuildContext context) {
    final color = TripStayLabels.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        TripStayLabels.status(status, AppLocalizations.of(context)!),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
