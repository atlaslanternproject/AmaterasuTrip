// Etichetta della cancellazione gratuita di un soggiorno, ben visibile:
// verde con la data quando manca tempo, colore di avviso negli ultimi
// giorni (con i giorni che mancano), spenta quando la data è passata.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_cancellation.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStayCancellationChip extends StatelessWidget {
  const TripStayCancellationChip({super.key, required this.stay, this.today});

  final TripStay stay;

  /// "Today" for the countdown; tests set it.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final state = TripStayCancellation.state(stay, now);
    final until = stay.freeCancellationUntil;
    if (state == null || until == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final date = MaterialLocalizations.of(context).formatMediumDate(until);
    final (color, text, icon) = switch (state) {
      TripStayCancellationState.open => (
        AmaterasuColors.success,
        l10n.staysCancellationUntil(date),
        Icons.event_available_outlined,
      ),
      TripStayCancellationState.soon => (
        AmaterasuColors.error,
        l10n.staysCancellationSoon(
          TripStayCancellation.daysLeft(stay, now)!,
          date,
        ),
        Icons.warning_amber_rounded,
      ),
      TripStayCancellationState.expired => (
        AmaterasuColors.textMuted,
        l10n.staysCancellationExpired(date),
        Icons.event_busy_outlined,
      ),
    };
    return Container(
      key: Key('stay-cancellation-${state.name}-${stay.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
