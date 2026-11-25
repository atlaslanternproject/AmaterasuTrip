// Tratto tra due tappe consecutive dell'Itinerario: distanza in linea
// d'aria (km o miglia secondo Aspetto) e "Apri a piedi su Google Maps"
// (nessuna API di percorso, AmaterasuLinkOpener.openMaps).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_day_content.dart';

/// Walking route on Google Maps between two places (no route API).
Uri tripItineraryWalkUri(TripItineraryPlace a, TripItineraryPlace b) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${a.latitude},${a.longitude}',
      'destination': '${b.latitude},${b.longitude}',
      'travelmode': 'walking',
    });

class TripItineraryLeg extends StatelessWidget {
  const TripItineraryLeg({
    super.key,
    required this.from,
    required this.to,
    required this.actions,
  });

  final TripItineraryItem from, to;
  final TripItineraryActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final km = TripItineraryLogic.distanceKm(from.place, to.place)!;
    return Padding(
      key: Key('itinerary-leg-${from.id}'),
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          const Icon(
            Icons.directions_walk,
            size: 16,
            color: AmaterasuColors.textMuted,
          ),
          Text(
            l10n.itineraryLeg(
              TripItineraryLogic.distanceLabel(km, actions.units),
              to.title,
            ),
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 12,
            ),
          ),
          AmaterasuButton.tertiary(
            key: Key('itinerary-walk-${from.id}'),
            onPressed: () => AmaterasuLinkOpener.openMaps(
              context,
              tripItineraryWalkUri(from.place!, to.place!),
              failedMessage: l10n.itineraryMapsFailed,
              launch: actions.launch ?? AmaterasuLinkOpener.defaultLaunch,
            ),
            label: l10n.itineraryWalk,
          ),
        ],
      ),
    );
  }
}
