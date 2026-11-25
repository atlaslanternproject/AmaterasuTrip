// Vista mappa comune a Mappa e Itinerario: la mappa (o quella finta dei
// test), il numero dei luoghi mostrati e il riquadro del luogo toccato.
// Le linee tratteggiate uniscono le voci di ogni giorno in ordine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_canvas.dart';
import 'trip_map_panel.dart';
import 'trip_map_point.dart';

/// Itinerary items with a position, one route per day in order.
List<List<TripItineraryItem>> tripMapRoutes(List<TripItineraryItem> items) {
  final days = {for (final i in items) TripItineraryLogic.dateOnly(i.day)};
  return [
    for (final d in days.toList()..sort())
      if (tripMapPoints(TripItineraryLogic.ofDay(items, d)) case final r
          when r.length > 1)
        r,
  ];
}

class TripMapView extends ConsumerStatefulWidget {
  const TripMapView({
    super.key,
    required this.tripId,
    required this.points,
    required this.routes,
    this.unscheduled = const {},
  });

  final String tripId;
  final List<TripItineraryItem> points;
  final List<List<TripItineraryItem>> routes;

  /// IDs of elements not in the itinerary (no day in the panel).
  final Set<String> unscheduled;

  @override
  ConsumerState<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends ConsumerState<TripMapView> {
  TripItineraryItem? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canvas = ref.watch(tripMapCanvasProvider);
    final selected = _selected;
    return Stack(
      children: [
        Positioned.fill(
          child: canvas(
            widget.points,
            widget.routes,
            (i) => setState(() => _selected = i),
          ),
        ),
        Positioned(
          top: 8,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AmaterasuColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.mapPlaces(widget.points.length),
              key: const Key('map-count'),
              style: const TextStyle(
                color: AmaterasuColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TripMapPanel(
                  tripId: widget.tripId,
                  item: selected,
                  scheduled: !widget.unscheduled.contains(selected.id),
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
