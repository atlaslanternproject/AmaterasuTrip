// Vista mappa comune a Mappa e Itinerario: la mappa (o quella finta dei
// test), il numero dei luoghi mostrati (e di quelli senza posizione, che
// si toccano per vederne l'elenco) e il riquadro del luogo toccato. Linee tratteggiate per giorno, in ordine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_canvas.dart';
import 'trip_map_missing.dart';
import 'trip_map_panel.dart';
import 'trip_map_point.dart';

int _minutes(String? t) => t == null || t.length < 5
    ? 24 * 60
    : int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));

/// One route per day: the points of that day by time (two or more).
List<List<TripMapPoint>> tripMapRoutes(List<TripMapPoint> points) {
  final byDay = <DateTime, List<TripMapPoint>>{};
  for (final p in points) {
    if (p.day == null) continue;
    byDay.putIfAbsent(TripItineraryLogic.dateOnly(p.day!), () => []).add(p);
  }
  return [
    for (final d in byDay.keys.toList()..sort())
      if (byDay[d]!.length > 1)
        byDay[d]!..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time))),
  ];
}

class TripMapView extends ConsumerStatefulWidget {
  const TripMapView({
    super.key,
    required this.tripId,
    required this.points,
    required this.routes,
    this.dimmed = const {},
    this.withoutPosition = const [],
  });

  final String tripId;
  final List<TripMapPoint> points;
  final List<List<TripMapPoint>> routes;

  /// Points shown faded (not on the chosen day).
  final Set<String> dimmed;

  /// Elements with no position (not on the map: listed on a tap).
  final List<TripItineraryRef> withoutPosition;

  @override
  ConsumerState<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends ConsumerState<TripMapView> {
  TripMapPoint? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canvas = ref.watch(tripMapCanvasProvider);
    final selected = _selected;
    final missing = widget.withoutPosition;
    return Stack(
      children: [
        Positioned.fill(
          child: canvas(
            widget.points,
            widget.routes,
            (p) => setState(() => _selected = p),
            widget.dimmed,
          ),
        ),
        Positioned(
          top: 8,
          left: 12,
          right: 64,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AmaterasuColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: missing.isEmpty
                    ? null
                    : () => showTripMapMissing(
                        context,
                        tripId: widget.tripId,
                        missing: missing,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          [
                            l10n.mapPlaces(widget.points.length),
                            if (missing.isNotEmpty)
                              l10n.mapWithoutPosition(missing.length),
                          ].join(' · '),
                          key: const Key('map-count'),
                          style: const TextStyle(
                            color: AmaterasuColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (missing.isNotEmpty)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AmaterasuColors.textMuted,
                        ),
                    ],
                  ),
                ),
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
                  point: selected,
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
