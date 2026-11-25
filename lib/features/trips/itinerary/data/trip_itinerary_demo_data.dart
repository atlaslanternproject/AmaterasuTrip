// Dati di esempio della bozza: 4 giorni a Kyoto da oggi, 14 voci con
// riferimenti di ogni sezione, voci libere, una giornata libera, un
// "previsto / fatto", una sovrapposizione, tre zone (Gion, Arashiyama,
// Fushimi) e voci senza zona; coordinate vere; persone Yato e Leo.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_demo_builders.dart';

const tripItineraryDemoNames = {demoYato: 'Yato', demoLeo: 'Leo'};

const _booked = TripBookingStatus.booked;
const _toBook = TripBookingStatus.toBook;

List<TripItineraryItem> tripItineraryDemoItems(DateTime s) => [
  demoRef(
    'i1',
    0,
    s,
    TripSearchSection.transports,
    'Shinkansen Tokyo → Kyoto',
    '09:30',
    demoPlace('Stazione di Kyoto', 34.9858, 135.7588),
    status: _booked,
  ),
  demoRef(
    'i2',
    0,
    s,
    TripSearchSection.stays,
    'Ryokan Gion Hatanaka',
    '15:00',
    demoPlace('Ryokan Gion Hatanaka', 35.0026, 135.7787, 'Gion'),
    status: _booked,
  ),
  demoFree(
    'i3',
    0,
    s,
    'Passeggiata a Hanamikoji',
    '17:30',
    demoPlace('Hanamikoji', 35.0028, 135.7750, 'Gion'),
  ),
  demoRef(
    'i4',
    0,
    s,
    TripSearchSection.restaurants,
    'Gion Karyo',
    '19:00',
    demoPlace('Gion Karyo', 35.0037, 135.7752, 'Gion'),
    status: _booked,
    person: demoLeo,
  ),
  demoFree(
    'i5',
    0,
    s,
    'Souvenir in Shijo-dori',
    null,
    demoPlace('Shijo-dori', 35.0039, 135.7703, 'Gion'),
    person: demoYato,
  ),
  demoRef(
    'i6',
    1,
    s,
    TripSearchSection.savedPlaces,
    'Bosco di bambù',
    '08:30',
    demoPlace('Bosco di bambù di Arashiyama', 35.0170, 135.6713, 'Arashiyama'),
  ),
  demoRef(
    'i7',
    1,
    s,
    TripSearchSection.reservations,
    'Tenryū-ji',
    '09:00',
    demoPlace('Tenryū-ji', 35.0156, 135.6738, 'Arashiyama'),
    status: _booked,
    person: demoLeo,
  ),
  demoFree(
    'i8',
    1,
    s,
    'Pranzo da Shoraian',
    '12:00',
    demoPlace('Shoraian', 35.0109, 135.6779, 'Arashiyama'),
    actual: 'Pranzo veloce al mercato di Saga',
  ),
  demoRef(
    'i9',
    1,
    s,
    TripSearchSection.bucketList,
    'Barca sul fiume Hozu',
    '13:30',
    demoPlace('Imbarco Hozugawa', 35.0136, 135.6781, 'Arashiyama'),
    status: _toBook,
  ),
  demoRef(
    'i10',
    1,
    s,
    TripSearchSection.restaurants,
    'Ramen Ichiran',
    '19:30',
    demoPlace('Ichiran Kyoto Kawaramachi', 35.0047, 135.7700, 'Gion'),
    status: _toBook,
  ),
  demoRef(
    'i11',
    2,
    s,
    TripSearchSection.savedPlaces,
    'Fushimi Inari Taisha',
    '07:30',
    demoPlace('Fushimi Inari Taisha', 34.9671, 135.7727, 'Fushimi'),
    person: demoLeo,
  ),
  demoFree(
    'i12',
    2,
    s,
    'Degustazione di sake',
    '14:00',
    demoPlace('Gekkeikan Okura', 34.9318, 135.7613, 'Fushimi'),
  ),
  TripItineraryItem(
    id: 'i13',
    day: s.add(const Duration(days: 3)),
    kind: TripItineraryKind.freeDay,
    title: 'Mattina libera',
    personUid: demoYato,
  ),
  demoRef(
    'i14',
    3,
    s,
    TripSearchSection.transports,
    'Treno per Kansai Airport',
    '11:00',
    demoPlace('Stazione di Kyoto', 34.9858, 135.7588),
    status: _booked,
  ),
];

/// Elements with a position that are not in the itinerary.
List<TripItineraryItem> tripItineraryDemoCatalog(DateTime s) => [
  demoRef(
    'c1',
    0,
    s,
    TripSearchSection.savedPlaces,
    'Kinkaku-ji',
    null,
    demoPlace('Kinkaku-ji', 35.0394, 135.7292),
  ),
  demoRef(
    'c2',
    0,
    s,
    TripSearchSection.bucketList,
    'Mercato di Nishiki',
    null,
    demoPlace('Mercato di Nishiki', 35.0050, 135.7649, 'Gion'),
  ),
  demoRef(
    'c3',
    0,
    s,
    TripSearchSection.savedPlaces,
    'Kiyomizu-dera',
    null,
    demoPlace('Kiyomizu-dera', 34.9949, 135.7850, 'Gion'),
    person: demoLeo,
  ),
];
