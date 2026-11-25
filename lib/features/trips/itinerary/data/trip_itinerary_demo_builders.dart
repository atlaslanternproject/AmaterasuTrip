// Piccoli costruttori delle voci di esempio della bozza (riferimento,
// voce libera, luogo con zona) e le due persone di prova, Yato e Leo.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import '../models/trip_itinerary_item.dart';

const demoYato = 'demo-yato';
const demoLeo = 'demo-leo';

TripItineraryPlace demoPlace(
  String name,
  double lat,
  double lng, [
  String? zone,
]) => TripItineraryPlace(name: name, latitude: lat, longitude: lng, zone: zone);

TripItineraryItem demoRef(
  String id,
  int day,
  DateTime start,
  TripSearchSection s,
  String title,
  String? time,
  TripItineraryPlace place, {
  TripBookingStatus? status,
  String person = demoYato,
}) => TripItineraryItem(
  id: id,
  day: start.add(Duration(days: day)),
  kind: TripItineraryKind.ref,
  title: title,
  time: time,
  section: s,
  refId: 'demo-$id',
  place: place,
  status: status,
  personUid: person,
);

TripItineraryItem demoFree(
  String id,
  int day,
  DateTime start,
  String title,
  String? time,
  TripItineraryPlace? place, {
  String? actual,
  String person = demoLeo,
}) => TripItineraryItem(
  id: id,
  day: start.add(Duration(days: day)),
  kind: TripItineraryKind.free,
  title: title,
  time: time,
  place: place,
  actual: actual,
  personUid: person,
);
