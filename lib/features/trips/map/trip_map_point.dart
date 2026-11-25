// Punto sulla Mappa: un elemento con posizione (voce dell'itinerario o
// elemento di una sezione), con sezione, giorno, ora, stato e persona per
// i filtri; e il raggruppamento dei punti a griglia secondo lo zoom.

import 'dart:math' as math;

import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';

/// Map points of [items] (only those with a position).
List<TripItineraryItem> tripMapPoints(Iterable<TripItineraryItem> items) => [
  for (final i in items)
    if (i.place?.hasPosition ?? false) i,
];

class TripMapCluster {
  const TripMapCluster(this.items);

  final List<TripItineraryItem> items;

  double get latitude =>
      items.map((i) => i.place!.latitude!).reduce((a, b) => a + b) /
      items.length;

  double get longitude =>
      items.map((i) => i.place!.longitude!).reduce((a, b) => a + b) /
      items.length;

  bool get single => items.length == 1;

  /// Zoom that separates the items (two steps closer, at most 18).
  double zoomIn(double zoom) => math.min(zoom + 2, 18);
}

/// Groups points in cells of about [cellPixels] screen pixels at [zoom]
/// (256-pixel world tiles): one cluster per cell, in a stable order.
List<TripMapCluster> tripMapClusters(
  List<TripItineraryItem> points,
  double zoom, {
  double cellPixels = 64,
}) {
  final cell = 360 / math.pow(2, zoom) * cellPixels / 256;
  final cells = <String, List<TripItineraryItem>>{};
  for (final p in points) {
    final x = (p.place!.longitude! / cell).floor();
    final y = (p.place!.latitude! / cell).floor();
    cells.putIfAbsent('$x:$y', () => []).add(p);
  }
  return [for (final c in cells.values) TripMapCluster(c)];
}
