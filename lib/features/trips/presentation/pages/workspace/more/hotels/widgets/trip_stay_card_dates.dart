// Riquadro delle date nella card di un soggiorno: check-in a sinistra,
// check-out a destra (giorno in evidenza e orario sotto) e, in mezzo, le
// notti. Su schermo stretto i testi vanno a capo senza uscire.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStayCardDates extends StatelessWidget {
  const TripStayCardDates({super.key, required this.stay});

  final TripStay stay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = MaterialLocalizations.of(context).formatMediumDate;
    return Container(
      key: Key('stay-dates-${stay.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        children: [
          Expanded(
            child: _End(
              label: l10n.staysCheckIn,
              day: format(stay.checkInDate),
              time: stay.checkInTime,
              icon: Icons.login_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AmaterasuColors.accentBudget.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nightlight_round, size: 14,
                      color: AmaterasuColors.accentGold),
                  const SizedBox(width: 5),
                  Text(
                    l10n.staysNights(stay.nights),
                    style: const TextStyle(color: AmaterasuColors.accentGold,
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _End(
              label: l10n.staysCheckOut,
              day: format(stay.checkOutDate),
              time: stay.checkOutTime,
              icon: Icons.logout_rounded,
              end: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({
    required this.label,
    required this.day,
    required this.time,
    required this.icon,
    this.end = false,
  });

  final String label;
  final String day;
  final String? time;
  final IconData icon;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AmaterasuColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AmaterasuColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        day,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: const TextStyle(color: AmaterasuColors.textPrimary,
            fontSize: 15, fontWeight: FontWeight.w700),
      ),
      if (time != null)
        Text(time!, style: const TextStyle(
            color: AmaterasuColors.accentGold, fontSize: 13,
            fontWeight: FontWeight.w600)),
    ],
  );
}
