// Riga essenziale di un soggiorno per la vista "Dettagli": icona del tipo,
// nome, periodo con notti e stato colorato, un avviso quando la
// cancellazione gratuita sta per scadere, e a destra le azioni rapide
// come icone. Una riga per alloggio, senza foto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_cancellation.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_labels.dart';

class TripStayDetailsRow extends StatelessWidget {
  const TripStayDetailsRow({
    super.key,
    required this.stay,
    required this.actions,
    this.today,
  });

  final TripStay stay;
  final Widget actions;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelled = !stay.isActive;
    final now = today ?? DateTime.now();
    return Container(
      key: Key('stay-row-${stay.id}'),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        children: [
          Icon(
            TripStayLabels.typeIcon(stay.type),
            size: 20,
            color: AmaterasuColors.accentBudget,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stay.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cancelled
                        ? AmaterasuColors.textMuted
                        : AmaterasuColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${TripStayLabels.period(context, stay)} · ',
                      ),
                      TextSpan(
                        text: TripStayLabels.status(stay.status, l10n),
                        style: TextStyle(
                          color: TripStayLabels.statusColor(stay.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AmaterasuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (TripStayCancellation.state(stay, now) ==
              TripStayCancellationState.soon)
            Tooltip(
              message: l10n.staysCancellationSoon(
                TripStayCancellation.daysLeft(stay, now)!,
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(stay.freeCancellationUntil!),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                key: Key('stay-row-cancellation-${stay.id}'),
                size: 18,
                color: AmaterasuColors.error,
              ),
            ),
          actions,
        ],
      ),
    );
  }
}
