// Gruppo "Fuori dalle date" dell'Itinerario (decisione 12): le voci con un
// giorno fuori dalle date del viaggio (le date sono cambiate), con la loro
// data e l'invito ad aprirle per scegliere un giorno. Usato da Linea del
// tempo e Giorno per giorno.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_tile.dart';

class TripItineraryOutside extends StatelessWidget {
  const TripItineraryOutside({
    super.key,
    required this.items,
    required this.actions,
  });

  final List<TripItineraryItem> items;
  final TripItineraryActions actions;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const Key('itinerary-outside'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            l10n.itineraryOutsideDates,
            style: const TextStyle(
              color: AmaterasuColors.accentGold,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.itineraryOutsideDatesHint,
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        for (final i in items) ...[
          Text(
            AmaterasuDates.day(context, i.day),
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 12,
            ),
          ),
          TripItineraryTile(
            item: i,
            onEdit: () => actions.onEdit(i),
            onDelete: actions.canDelete(i) ? () => actions.onDelete(i) : null,
          ),
        ],
      ],
    );
  }
}
