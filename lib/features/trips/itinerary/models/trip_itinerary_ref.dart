// Elemento di una sezione che l'Itinerario può collegare (catalogo letto con
// la Mappa): sezione, identificativo, nome, luogo se c'è e stato attuale.
// Una voce collegata mostra sempre questi dati aggiornati.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'trip_itinerary_item.dart';

class TripItineraryRef {
  const TripItineraryRef({
    required this.section,
    required this.refId,
    required this.title,
    this.zone,
    this.place,
    this.status,
  });

  final TripSearchSection section;
  final String refId, title;
  final String? zone;
  final TripItineraryPlace? place;
  final TripBookingStatus? status;

  /// The same element with its position (zone kept), or without one.
  TripItineraryRef at(TripItineraryPlace? found) => TripItineraryRef(
    section: section,
    refId: refId,
    title: title,
    zone: zone,
    status: status,
    place: found == null
        ? (zone == null ? null : TripItineraryPlace(name: title, zone: zone))
        : TripItineraryPlace(
            name: found.name,
            latitude: found.latitude,
            longitude: found.longitude,
            zone: zone ?? found.zone,
          ),
  );

  /// Key of the element ("section/id"), as the itinerary links it.
  String get key => '${section.name}/$refId';

  /// A new item that links this element, on [day], added by [uid].
  TripItineraryItem newItem({
    required String tripId,
    required String uid,
    required DateTime day,
  }) => TripItineraryItem(
    tripId: tripId,
    createdByUid: uid,
    day: day,
    kind: TripItineraryKind.ref,
    title: title,
    section: section,
    refId: refId,
    place: place,
    status: status,
  );

  /// [item] with the live data of this element (name, place, status).
  TripItineraryItem applyTo(TripItineraryItem item) => item.copyWith(
    title: title,
    place: () => place ?? item.place,
    status: () => status,
  );
}
