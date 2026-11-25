// Voce dell'Itinerario (docs/design/MAPPA-ITINERARIO.md), salvata in
// trips/{tripId}/itinerary: riferimento a un elemento di una sezione, voce
// libera o giornata libera; giorno, ora e ora di fine facoltative, ordine a
// mano, luogo con zona, "fatto invece" (testo o elemento). L'autore è chi
// l'ha aggiunta (filtro persona).

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';

enum TripItineraryKind { ref, free, freeDay }

/// A position on the map with its zone (area or city).
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

class TripItineraryItem implements TripSectionItem {
  const TripItineraryItem({
    this.id = '',
    this.tripId = '',
    this.createdByUid = '',
    required this.day,
    required this.kind,
    required this.title,
    this.time,
    this.endTime,
    this.order = 0,
    this.section,
    this.refId,
    this.place,
    this.note,
    this.status,
    this.actual,
    this.actualSection,
    this.actualRefId,
  });

  @override
  final String id;
  @override
  final String tripId;

  /// Who added the item (person filter).
  @override
  final String createdByUid;

  /// Calendar day (time ignored).
  final DateTime day;
  final TripItineraryKind kind;
  final String title;

  /// "HH:MM" or null; [endTime] optional end of the item.
  final String? time, endTime;
  final int order;

  /// Section of a reference (same codes and icons as Cerca).
  final TripSearchSection? section;
  final String? refId;
  final TripItineraryPlace? place;
  final String? note;

  /// Status of the referenced element (read from its section, not saved).
  final TripBookingStatus? status;

  /// "Fatto invece": free text and/or an element of a section.
  final String? actual;
  final TripSearchSection? actualSection;
  final String? actualRefId;

  @override
  String? get expenseId => null;

  @override
  String get displayName => title;

  String? get zone => place?.zone;

  /// Who added the item (person filter).
  String get personUid => createdByUid;

  TripItineraryItem copyWith({
    String? id,
    DateTime? day,
    String? Function()? time,
    String? Function()? endTime,
    int? order,
    String? title,
    String? Function()? note,
    String? Function()? actual,
    TripItineraryPlace? Function()? place,
    TripBookingStatus? Function()? status,
  }) => TripItineraryItem(
    id: id ?? this.id,
    tripId: tripId,
    createdByUid: createdByUid,
    day: day ?? this.day,
    kind: kind,
    title: title ?? this.title,
    time: time == null ? this.time : time(),
    endTime: endTime == null ? this.endTime : endTime(),
    order: order ?? this.order,
    section: section,
    refId: refId,
    place: place == null ? this.place : place(),
    note: note == null ? this.note : note(),
    status: status == null ? this.status : status(),
    actual: actual == null ? this.actual : actual(),
    actualSection: actualSection,
    actualRefId: actualRefId,
  );
}
