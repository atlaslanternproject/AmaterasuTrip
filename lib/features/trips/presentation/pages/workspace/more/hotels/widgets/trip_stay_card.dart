// Card di un soggiorno, nello stile della card della bucket list: foto
// Google in testa, nome e città, stato e tipo di alloggio, riquadro con
// check-in, check-out e notti, prenotazione e ospiti, link con Mappa e
// Contatta, spesa collegata (se data) e menu modifica/elimina.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'trip_stay_card_dates.dart';
import 'trip_stay_card_details.dart';
import 'trip_stay_card_links.dart';
import 'trip_stay_card_menu.dart';
import 'trip_stay_photo_carousel.dart';
import 'trip_stay_status_chip.dart';
import 'trip_stay_type_chip.dart';

class TripStayCard extends StatelessWidget {
  const TripStayCard({
    super.key,
    required this.stay,
    required this.guestNames,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
    this.footer,
    this.launch,
  });

  final TripStay stay;
  final List<String> guestNames;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Extra content at the bottom (linked expense).
  final Widget? footer;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final cancelled = !stay.isActive;
    final place = [stay.city, stay.country]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return Container(
      key: Key('stay-card-${stay.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceSheet,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmaterasuColors.borderAccent, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: cancelled ? 0.5 : 1,
                  child: TripStayPhotoCarousel(
                    placeId: stay.googlePlaceId,
                    type: stay.type,
                    height: wide ? 220 : 160,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stay.name,
                          style: TextStyle(
                            color: cancelled
                                ? AmaterasuColors.textMuted
                                : AmaterasuColors.textCream,
                            fontSize: wide ? 21 : 19,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            decoration:
                                cancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _Place(place),
                        ],
                      ],
                    ),
                  ),
                  TripStayCardMenu(
                    stayId: stay.id,
                    canEdit: onEdit != null,
                    canDelete: canDelete && onDelete != null,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  TripStayStatusChip(status: stay.status),
                  if (stay.type case final type?) TripStayTypeChip(type: type),
                ],
              ),
              const SizedBox(height: 12),
              TripStayCardDates(stay: stay),
              TripStayCardDetails(stay: stay, guestNames: guestNames),
              TripStayCardLinks(stay: stay, launch: launch),
              ?footer,
            ],
          );
        },
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.location_on_outlined, size: 16,
          color: AmaterasuColors.textSecondary),
      const SizedBox(width: 4),
      Expanded(
        child: Text(text, style: const TextStyle(
            color: AmaterasuColors.textSecondary, fontSize: 13)),
      ),
    ],
  );
}
