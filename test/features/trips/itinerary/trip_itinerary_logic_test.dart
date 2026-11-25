// Test dei calcoli e dei dati dell'Itinerario: gruppi per zona,
// sovrapposizioni (con ora di fine), giorni vuoti, distanza in linea
// d'aria, pin raggruppati, codec da e verso Firestore, dati aggiornati
// degli elementi collegati e riordino delle sole voci senza ora.

import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_codec.dart';
import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_repository.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sections/support/fake_section_store.dart';
import 'support/itinerary_fixtures.dart';

void main() {
  test('zones by the time of their first item, no zone included', () {
    final zones = TripItineraryLogic.zones(
      TripItineraryLogic.ofDay(itineraryItems, itineraryDay(0)),
    );
    expect([for (final (z, _) in zones) z], [null, 'Gion']);
  });

  test('overlaps: one hour without an end, the end time when there is one', () {
    final day = TripItineraryLogic.ofDay(itineraryItems, itineraryDay(1));
    expect(
      TripItineraryLogic.overlaps(day).map((p) => '${p.$1.id}-${p.$2.id}'),
      ['i6-i7'],
    );
    final short = [
      entry('a', 1, 'A', time: '08:30', endTime: '08:45'),
      entry('b', 1, 'B', time: '09:00'),
    ];
    expect(TripItineraryLogic.overlaps(short), isEmpty);
    expect(
      TripItineraryLogic.emptyDays(itineraryItems, [
        itineraryDay(0),
        itineraryDay(5),
      ]),
      [itineraryDay(5)],
    );
  });

  test('trip days: undated trips, items outside the dates', () {
    final zero = DateTime.fromMillisecondsSinceEpoch(0);
    expect(TripItineraryLogic.undated(zero, zero), isTrue);
    expect(
      TripItineraryLogic.undated(itineraryStart, itineraryDay(2)),
      isFalse,
    );
    final days = TripItineraryLogic.days(itineraryStart, itineraryDay(1));
    expect(TripItineraryLogic.outside(itineraryItems, days).map((i) => i.id), [
      'i9',
    ]);
  });

  test('distance and pins', () {
    final km = TripItineraryLogic.distanceKm(
      itineraryItems[4].place,
      itineraryItems[5].place,
    )!;
    expect(km, closeTo(0.32, 0.1));
    final points = [for (final i in itineraryItems) ?TripMapPoint.ofItem(i)];
    expect(points, hasLength(7)); // the free day has no place
    expect(tripMapClusters(points, 18).length, greaterThanOrEqualTo(6));
  });

  test('codec: round trip, status not saved, checks', () {
    const codec = TripItineraryCodec();
    final item = itineraryItems[6].copyWith(
      endTime: () => '13:00',
      status: () => TripBookingStatus.booked,
    );
    final map = codec.toMap(item);
    expect(map['day'], '2027-04-11');
    expect(map.containsKey('status'), isFalse);
    expect(map['actualText'], 'Pranzo al mercato');
    final back = codec.fromMap('i8', map);
    expect(back.title, 'Pranzo da Shoraian');
    expect(back.time, '12:00');
    expect(back.endTime, '13:00');
    expect(back.zone, 'Arashiyama');
    expect(codec.problems(item.copyWith(title: ' ')), isNotEmpty);
    expect(codec.problems(item.copyWith(time: () => '9:00')), isNotEmpty);
  });

  test('linked items show the current data of their element', () {
    final linked = itineraryCatalog.first.applyTo(itineraryItems[5]);
    expect(linked.title, 'Tenryū-ji (biglietto)');
    expect(linked.status, TripBookingStatus.booked);
    expect(linked.place?.latitude, isNotNull);
  });

  test(
    'reorder writes only the changed order, items keep their time',
    () async {
      final store = FakeSectionStore<TripItineraryItem>(items: itineraryItems);
      final repo = StoreTripItineraryRepository(store);
      final untimed = [
        entry('x', 0, 'X').copyWith(order: 0),
        entry('y', 0, 'Y').copyWith(order: 1),
      ];
      await repo.reorder(untimed.reversed.toList());
      expect(store.updated.map((i) => '${i.id}:${i.order}'), ['y:0', 'x:1']);
    },
  );
}
