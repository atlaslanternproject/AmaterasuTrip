// Corpo dell'Itinerario: stato vuoto comune con l'invito ad aggiungere
// (l'itinerario lo costruisce l'utente), invito a impostare le date se il
// viaggio non le ha, oppure la vista scelta (linea del tempo, giorno per
// giorno, mappa delle voci con posizione).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_view.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_empty.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_day_view.dart';
import 'trip_itinerary_timeline.dart';
import 'trip_itinerary_view.dart';

class TripItineraryBody extends StatelessWidget {
  const TripItineraryBody({
    super.key,
    required this.tripId,
    required this.loading,
    required this.view,
    required this.all,
    required this.shown,
    required this.days,
    required this.actions,
    required this.filtered,
    required this.onAdd,
    required this.onReorder,
  });

  final String tripId;

  /// The trip is still loading (its days are not known yet).
  final bool loading;
  final TripItineraryView view;
  final List<TripItineraryItem> all, shown;
  final List<DateTime> days;
  final TripItineraryActions actions;
  final bool filtered;
  final VoidCallback onAdd;
  final ValueChanged<List<TripItineraryItem>> onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) return const Center(child: AmaterasuLoader());
    if (days.isEmpty) {
      return TripSectionEmpty(
        keyPrefix: 'itinerary-dates',
        icon: Icons.event_rounded,
        text: l10n.itineraryNoDates,
        addLabel: l10n.itineraryNoDatesAction,
        onAdd: () => context.push('/trips/$tripId/settings/information'),
      );
    }
    if (all.isEmpty) {
      return TripSectionEmpty(
        keyPrefix: 'itinerary',
        icon: Icons.route_rounded,
        text: l10n.itineraryEmptyState,
        addLabel: l10n.itineraryAdd,
        onAdd: onAdd,
      );
    }
    final points = [for (final i in shown) ?TripMapPoint.ofItem(i)];
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: view == TripItineraryView.map ? double.infinity : 820,
        ),
        child: switch (view) {
          TripItineraryView.timeline => TripItineraryTimeline(
            all: all,
            shown: shown,
            days: days,
            actions: actions,
          ),
          TripItineraryView.day => TripItineraryDayView(
            all: all,
            shown: shown,
            days: days,
            actions: actions,
            filtered: filtered,
            onReorder: onReorder,
          ),
          TripItineraryView.map => TripMapView(
            tripId: tripId,
            points: points,
            routes: tripMapRoutes(points),
          ),
        },
      ),
    );
  }
}
