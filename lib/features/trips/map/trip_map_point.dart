// Punto sulla Mappa: un elemento con posizione di una sezione (o una voce
// dell'itinerario), con sezione, giorno se c'è, ora, stato e persona per i
// filtri; e il raggruppamento dei punti a griglia secondo lo zoom.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';

class TripMapPoint {
  const TripMapPoint({
    required this.id,
    required this.title,
    required this.place,
    this.section,
    this.refId,
    this.day,
    this.time,
    this.status,
    this.personUid,
    this.freeDay = false,
  });

  /// Point of an itinerary item (null when the item has no position).
  static TripMapPoint? ofItem(TripItineraryItem i) =>
      (i.place?.hasPosition ?? false)
      ? TripMapPoint(
          id: i.id,
          title: i.title,
          place: i.place!,
          section: i.section,
          refId: i.refId,
          day: i.day,
          time: i.time,
          status: i.status,
          personUid: i.personUid,
        )
      : null;

  final String id, title;
  final TripItineraryPlace place;
  final TripSearchSection? section;

  /// ID of the element in its section ("Apri la sezione").
  final String? refId;

  /// Day of the element, when it has one (null: not planned on a day).
  final DateTime? day;
  final String? time;
  final TripBookingStatus? status;

  /// Who added the element (person filter).
  final String? personUid;
  final bool freeDay;

  /// Section icon (a free item: the note icon).
  IconData get icon => section?.icon ?? Icons.edit_note_rounded;

  double get latitude => place.latitude!;
  double get longitude => place.longitude!;
}

class TripMapCluster {
  const TripMapCluster(this.points);

  final List<TripMapPoint> points;

  double get latitude =>
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;

  double get longitude =>
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

  bool get single => points.length == 1;

  /// Zoom that separates the points (two steps closer, at most 18).
  double zoomIn(double zoom) => math.min(zoom + 2, 18);
}

/// Groups points in cells of about [cellPixels] screen pixels at [zoom]
/// (256-pixel world tiles): one cluster per cell, in a stable order.
List<TripMapCluster> tripMapClusters(
  List<TripMapPoint> points,
  double zoom, {
  double cellPixels = 64,
}) {
  final cell = 360 / math.pow(2, zoom) * cellPixels / 256;
  final cells = <String, List<TripMapPoint>>{};
  for (final p in points) {
    final x = (p.longitude / cell).floor();
    final y = (p.latitude / cell).floor();
    cells.putIfAbsent('$x:$y', () => []).add(p);
  }
  return [for (final c in cells.values) TripMapCluster(c)];
}
