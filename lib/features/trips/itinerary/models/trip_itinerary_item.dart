// Voce dell'Itinerario (docs/design/MAPPA-ITINERARIO.md): riferimento a un
// elemento di una sezione, voce libera o giornata libera; giorno, ora
// facoltativa, ordine a mano, luogo con zona e "previsto / fatto invece".
// Nella bozza vive solo in memoria (TripItineraryRepository demo).

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';

enum TripItineraryKind { ref, free, freeDay }

/// A position on the map with its zone (neighbourhood or city).
class TripItineraryPlace {
  const TripItineraryPlace({
    required this.name,
    this.latitude,
    this.longitude,
    this.zone,
  });

  final String name;
  final double? latitude, longitude;

  /// Null: "Senza zona".
  final String? zone;

  bool get hasPosition => latitude != null && longitude != null;
}

class TripItineraryItem {
  const TripItineraryItem({
    required this.id,
    required this.day,
    required this.kind,
    required this.title,
    this.time,
    this.order = 0,
    this.section,
    this.refId,
    this.place,
    this.note,
    this.status,
    this.personUid,
    this.actual,
  });

  final String id;

  /// Calendar day (time ignored).
  final DateTime day;
  final TripItineraryKind kind;
  final String title;

  /// "HH:MM" or null.
  final String? time;
  final int order;

  /// Section of a reference (same codes and icons as Cerca).
  final TripSearchSection? section;
  final String? refId;
  final TripItineraryPlace? place;
  final String? note;
  final TripBookingStatus? status;

  /// Who added the item or takes care of it (person filter).
  final String? personUid;

  /// "Fatto invece": what was done instead of the plan.
  final String? actual;

  String? get zone => place?.zone;

  TripItineraryItem copyWith({
    DateTime? day,
    String? Function()? time,
    int? order,
    String? title,
    String? Function()? note,
    String? Function()? actual,
    TripItineraryPlace? Function()? place,
  }) => TripItineraryItem(
    id: id,
    day: day ?? this.day,
    kind: kind,
    title: title ?? this.title,
    time: time == null ? this.time : time(),
    order: order ?? this.order,
    section: section,
    refId: refId,
    place: place == null ? this.place : place(),
    note: note == null ? this.note : note(),
    status: status,
    personUid: personUid,
    actual: actual == null ? this.actual : actual(),
  );
}
