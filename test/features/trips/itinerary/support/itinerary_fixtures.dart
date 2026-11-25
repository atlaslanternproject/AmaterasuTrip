// Voci di prova dell'Itinerario per i test (solo nei test: l'app non ha più
// dati di esempio): 3 giorni a Kyoto, riferimenti, voci libere, giornata
// libera, "fatto invece", una sovrapposizione, zone e una voce senza zona.

import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';

final itineraryStart = DateTime(2027, 4, 10);
DateTime itineraryDay(int n) => itineraryStart.add(Duration(days: n));

TripItineraryPlace place(String name, double lat, double lng, [String? zone]) =>
    TripItineraryPlace(name: name, latitude: lat, longitude: lng, zone: zone);

TripItineraryItem entry(
  String id,
  int day,
  String title, {
  String? time,
  String? endTime,
  TripItineraryKind kind = TripItineraryKind.free,
  TripSearchSection? section,
  TripItineraryPlace? at,
  String author = 'anna',
  String? actual,
}) => TripItineraryItem(
  id: id,
  tripId: 't1',
  createdByUid: author,
  day: itineraryDay(day),
  kind: kind,
  title: title,
  time: time,
  endTime: endTime,
  section: section,
  refId: section == null ? null : 'ref-$id',
  place: at,
  actual: actual,
);

final itineraryItems = [
  entry(
    'i1',
    0,
    'Treno per Kyoto',
    time: '09:30',
    kind: TripItineraryKind.ref,
    section: TripSearchSection.transports,
    at: place('Stazione', 34.9858, 135.7588),
  ),
  entry(
    'i2',
    0,
    'Ryokan',
    time: '15:00',
    kind: TripItineraryKind.ref,
    section: TripSearchSection.stays,
    at: place('Ryokan', 35.0026, 135.7787, 'Gion'),
  ),
  entry(
    'i3',
    0,
    'Hanamikoji',
    time: '17:30',
    at: place('Hanamikoji', 35.0028, 135.7750, 'Gion'),
    author: 'bruno',
  ),
  entry('i4', 0, 'Souvenir', at: place('Shijo', 35.0039, 135.7703, 'Gion')),
  entry(
    'i6',
    1,
    'Bosco di bambù',
    time: '08:30',
    at: place('Bambù', 35.0170, 135.6713, 'Arashiyama'),
  ),
  entry(
    'i7',
    1,
    'Tenryū-ji',
    time: '09:00',
    kind: TripItineraryKind.ref,
    section: TripSearchSection.reservations,
    at: place('Tenryū-ji', 35.0156, 135.6738, 'Arashiyama'),
  ),
  entry(
    'i8',
    1,
    'Pranzo da Shoraian',
    time: '12:00',
    at: place('Shoraian', 35.0109, 135.6779, 'Arashiyama'),
    actual: 'Pranzo al mercato',
  ),
  entry('i9', 2, 'Mattina libera', kind: TripItineraryKind.freeDay),
];

/// The live data of the linked elements (catalog read with the map).
final itineraryCatalog = [
  const TripItineraryRef(
    section: TripSearchSection.reservations,
    refId: 'ref-i7',
    title: 'Tenryū-ji (biglietto)',
    zone: 'Arashiyama',
    status: TripBookingStatus.booked,
  ),
  const TripItineraryRef(
    section: TripSearchSection.savedPlaces,
    refId: 'kinkaku',
    title: 'Kinkaku-ji',
  ),
];
