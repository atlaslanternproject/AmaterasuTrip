// Card compatta di un soggiorno per la vista "Elenco": foto piccola a
// sinistra (come l'elenco della bucket list), nome, stato, tipo,
// cancellazione gratuita e periodo
// con le notti; sotto, le azioni rapide.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/widgets/amaterasu_place_photo_carousel.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'trip_stay_cancellation_chip.dart';
import 'trip_stay_labels.dart';
import 'trip_stay_status_chip.dart';
import 'trip_stay_type_chip.dart';

class TripStayCompactCard extends StatelessWidget {
  const TripStayCompactCard({
    super.key,
    required this.stay,
    required this.actions,
    this.today,
  });

  final TripStay stay;

  /// Map, expense, contact, edit… (always reachable).
  final Widget actions;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final cancelled = !stay.isActive;
    return Container(
      key: Key('stay-compact-${stay.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceSheet,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AmaterasuColors.borderAccent, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  child: Opacity(
                    opacity: cancelled ? 0.5 : 1,
                    child: AmaterasuPlacePhotoCarousel(
                      placeId: stay.googlePlaceId,
                      placeholderIcon: TripStayLabels.typeIcon(stay.type),
                      keyPrefix: 'stay',
                      height: 94,
                      controls: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stay.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cancelled
                            ? AmaterasuColors.textMuted
                            : AmaterasuColors.textCream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        TripStayStatusChip(status: stay.status),
                        if (stay.type case final type?)
                          TripStayTypeChip(type: type),
                        if (stay.isActive && stay.freeCancellationUntil != null)
                          TripStayCancellationChip(stay: stay, today: today),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TripStayLabels.period(context, stay),
                      style: const TextStyle(
                        color: AmaterasuColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      ),
    );
  }
}
