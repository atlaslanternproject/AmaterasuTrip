// Costruzione dei punti della Mappa dagli elementi delle sezioni: un punto
// solo se c'è la posizione; l'elenco conta gli elementi senza posizione
// (non compaiono sulla mappa).

import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'trip_map_point.dart';

/// Collects points, counts the elements without a position and keeps the
/// catalog of every element (with the first position, if any).
class TripMapPoints {
  final points = <TripMapPoint>[];
  final catalog = <TripItineraryRef>[];
  var missing = 0;

  /// Adds the element: its points with a position, and [ref] to the
  /// catalog.
  void add(List<TripMapPoint?> places, TripItineraryRef ref) {
    final found = places.whereType<TripMapPoint>().toList();
    found.isEmpty ? missing++ : points.addAll(found);
    catalog.add(ref.at(found.firstOrNull?.place));
  }
}

TripMapPoint? tripMapPointAt(
  String id,
  TripSearchSection section,
  String refId,
  String title,
  double? lat,
  double? lng, {
  String? placeName,
  String? zone,
  DateTime? day,
  String? time,
  TripBookingStatus? status,
  String? person,
}) => lat == null || lng == null
    ? null
    : TripMapPoint(
        id: id,
        title: title,
        place: TripItineraryPlace(
          name: placeName ?? title,
          latitude: lat,
          longitude: lng,
          zone: zone,
        ),
        section: section,
        refId: refId,
        day: day,
        time: time,
        status: status,
        personUid: person,
      );

TripMapPoint? tripMapPointOf(
  String id,
  TripSearchSection s,
  String refId,
  String title,
  TripSectionPlace p, {
  String? zone,
  DateTime? day,
  String? time,
  TripBookingStatus? status,
  String? person,
}) => tripMapPointAt(
  id,
  s,
  refId,
  title,
  p.latitude,
  p.longitude,
  placeName: p.name,
  zone: zone,
  day: day,
  time: time,
  status: status,
  person: person,
);
