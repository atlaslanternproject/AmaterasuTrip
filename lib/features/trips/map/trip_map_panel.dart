// Riquadro in basso della Mappa al tocco di un pin: miniatura quadrata,
// nome, sezione, giorno e ora se ci sono; "Apri la sezione" (stessa pagina
// di Cerca) e "Apri su Maps" (AmaterasuLinkOpener.openMaps). Chiudibile.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_thumb.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_point.dart';

class TripMapPanel extends StatelessWidget {
  const TripMapPanel({
    super.key,
    required this.tripId,
    required this.point,
    required this.onClose,
    this.launch,
  });

  final String tripId;
  final TripMapPoint point;
  final VoidCallback onClose;
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = point;
    final section = p.section;
    final details = [
      section?.label(l10n) ?? l10n.itineraryFreeItem,
      if (p.day != null) AmaterasuDates.day(context, p.day!),
      if (p.time != null) AmaterasuDates.time(context, p.time!),
    ];
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
              TripItineraryThumb(icon: p.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        color: AmaterasuColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      details.join(' · '),
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
              if (section != null)
                AmaterasuButton.secondary(
                  key: const Key('map-open-section'),
                  icon: section.icon,
                  label: l10n.mapOpenSection,
                  onPressed: () =>
                      context.go(section.route(tripId, p.refId ?? '')),
                ),
              AmaterasuButton.tertiary(
                key: const Key('map-open-maps'),
                icon: Icons.open_in_new,
                label: l10n.mapOpenMaps,
                onPressed: () => AmaterasuLinkOpener.openMaps(
                  context,
                  AmaterasuWebLink.googleMaps(
                    name: p.place.name,
                    latitude: p.latitude,
                    longitude: p.longitude,
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
