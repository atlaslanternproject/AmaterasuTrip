// Contenuto di un giorno dell'Itinerario (linea del tempo e giorno per
// giorno): avvisi di sovrapposizione, giornate libere in cima, poi gruppi
// per zona apribili (AmaterasuFoldSection) in ordine di orario della prima
// voce; tra due tappe distanza in linea d'aria e "Apri a piedi".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/widgets/inputs/amaterasu_fold_section.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_leg.dart';
import 'trip_itinerary_notice.dart';
import 'trip_itinerary_tile.dart';

/// What the item rows can do, shared by the views.
class TripItineraryActions {
  const TripItineraryActions({
    required this.onEdit,
    required this.onDelete,
    required this.units,
    this.launch,
  });

  final ValueChanged<TripItineraryItem> onEdit;
  final ValueChanged<TripItineraryItem> onDelete;

  /// "km" or "mi" from Aspetto.
  final String units;
  final AmaterasuLaunch? launch;
}

class TripItineraryDayContent extends StatelessWidget {
  const TripItineraryDayContent({
    super.key,
    required this.items,
    required this.actions,
  });

  /// Items of one day, already filtered.
  final List<TripItineraryItem> items;
  final TripItineraryActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordered = TripItineraryLogic.ofDay(items, items.first.day);
    final freeDays = ordered
        .where((i) => i.kind == TripItineraryKind.freeDay)
        .toList();
    final timedOrPlaced = ordered
        .where((i) => i.kind != TripItineraryKind.freeDay)
        .toList();
    final positioned = timedOrPlaced
        .where((i) => i.place?.hasPosition ?? false)
        .toList();
    TripItineraryItem? nextOf(TripItineraryItem i) {
      final k = positioned.indexOf(i);
      return k < 0 || k + 1 >= positioned.length ? null : positioned[k + 1];
    }

    Widget tile(TripItineraryItem i) => TripItineraryTile(
      item: i,
      onEdit: () => actions.onEdit(i),
      onDelete: () => actions.onDelete(i),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (a, b) in TripItineraryLogic.overlaps(timedOrPlaced))
          TripItineraryNotice(
            key: Key('itinerary-overlap-${a.id}'),
            text: l10n.itineraryOverlap(a.title, b.title),
          ),
        for (final f in freeDays) tile(f),
        for (final (zone, group) in TripItineraryLogic.zones(timedOrPlaced))
          AmaterasuFoldSection(
            key: Key('itinerary-zone-${zone ?? 'none'}-${group.first.id}'),
            title: zone ?? l10n.itineraryNoZone,
            icon: Icons.place_outlined,
            summary: l10n.itineraryZoneSummary(group.length),
            children: [
              for (final i in group) ...[
                tile(i),
                if (nextOf(i) case final next?)
                  TripItineraryLeg(from: i, to: next, actions: actions),
              ],
            ],
          ),
      ],
    );
  }
}
