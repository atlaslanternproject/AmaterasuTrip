// Riquadro in basso della Mappa al tocco di un pin: miniatura quadrata,
// nome, sezione, giorno e ora; "Apri la sezione" (stessa pagina di Cerca)
// e "Apri su Maps" (AmaterasuLinkOpener.openMaps). Chiudibile.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_tile.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripMapPanel extends StatelessWidget {
  const TripMapPanel({
    super.key,
    required this.tripId,
    required this.item,
    required this.onClose,
    this.scheduled = true,
    this.launch,
  });

  final String tripId;
  final TripItineraryItem item;
  final VoidCallback onClose;

  /// False for elements not in the itinerary: no day is shown.
  final bool scheduled;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final i = item;
    final place = i.place!;
    final when = [
      if (scheduled) AmaterasuDates.day(context, i.day),
      if (i.time != null) AmaterasuDates.time(context, i.time!),
    ].join(' · ');
    return Container(
      key: const Key('map-panel'),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AmaterasuColors.borderAccent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripItineraryThumb(icon: tripItineraryIcon(i)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.title,
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        tripItinerarySectionLabel(l10n, i),
                        if (when.isNotEmpty) when,
                      ].join(' · '),
                      style: const TextStyle(
                        color: AmaterasuColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('map-panel-close'),
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AmaterasuColors.textSecondary,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              if (i.section != null)
                AmaterasuButton.secondary(
                  key: const Key('map-open-section'),
                  icon: i.section!.icon,
                  label: l10n.mapOpenSection,
                  onPressed: () =>
                      context.go(i.section!.route(tripId, i.refId ?? '')),
                ),
              AmaterasuButton.tertiary(
                key: const Key('map-open-maps'),
                icon: Icons.open_in_new,
                label: l10n.mapOpenMaps,
                onPressed: () => AmaterasuLinkOpener.openMaps(
                  context,
                  AmaterasuWebLink.googleMaps(
                    name: place.name,
                    latitude: place.latitude,
                    longitude: place.longitude,
                  )!,
                  failedMessage: l10n.itineraryMapsFailed,
                  launch: launch ?? AmaterasuLinkOpener.defaultLaunch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
