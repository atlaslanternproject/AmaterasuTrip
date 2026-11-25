// Test dei calcoli della bozza di Itinerario e Mappa con i dati di esempio
// di Kyoto: giorni, ordine, gruppi per zona, sovrapposizioni, giorni
// vuoti, distanza in linea d'aria, raggruppamento dei pin e riordino demo.

import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_demo.dart';
import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_demo_data.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:flutter_test/flutter_test.dart';

final start = DateTime(2027, 4, 10);
final items = tripItineraryDemoItems(start);
DateTime day(int n) => start.add(Duration(days: n));

void main() {
  test('example data: 4 days, 14 items, every kind', () {
    expect(TripItineraryLogic.days(start, day(3)), hasLength(4));
    expect(items, hasLength(14));
    expect(
      items.map((i) => i.section?.name).toSet(),
      containsAll([
        'stays',
        'transports',
        'reservations',
        'restaurants',
        'savedPlaces',
        'bucketList',
        null,
      ]),
    );
    expect(items.where((i) => i.actual != null), hasLength(1));
  });

  test('zones by the time of their first item, no zone included', () {
    final zones = TripItineraryLogic.zones(
      TripItineraryLogic.ofDay(items, day(0)),
    );
    expect([for (final (z, _) in zones) z], [null, 'Gion']);
    final day2 = TripItineraryLogic.zones(
      TripItineraryLogic.ofDay(items, day(1)),
    );
    expect(
      [for (final (z, g) in day2) '$z:${g.length}'],
      ['Arashiyama:4', 'Gion:1'],
    );
  });

  test('overlap, empty days and distance', () {
    final overlaps = TripItineraryLogic.overlaps(
      TripItineraryLogic.ofDay(items, day(1)),
    );
    expect(overlaps.map((p) => '${p.$1.id}-${p.$2.id}'), ['i6-i7']);
    expect(TripItineraryLogic.emptyDays(items, [day(0), day(5)]), [day(5)]);
    final bamboo = items.firstWhere((i) => i.id == 'i6').place;
    final tenryu = items.firstWhere((i) => i.id == 'i7').place;
    final km = TripItineraryLogic.distanceKm(bamboo, tenryu)!;
    expect(km, closeTo(0.32, 0.1));
    expect(TripItineraryLogic.distanceLabel(1.609344, 'mi'), '1.0 mi');
    expect(TripItineraryLogic.distanceLabel(12.4, 'km'), '12 km');
  });

  test('pins: grouped far away, separate up close', () {
    final points = tripMapPoints(items);
    expect(points, hasLength(13)); // the free day has no place
    expect(tripMapClusters(points, 9).length, lessThan(5));
    expect(tripMapClusters(points, 18).length, greaterThanOrEqualTo(12));
  });

  test('demo reorder keeps everything in memory and drops the time', () async {
    final repo = DemoTripItineraryRepository(today: start);
    await repo.reorder('t', ['i8', 'i6']);
    final after = await repo.watch('t').first;
    final i8 = after.firstWhere((i) => i.id == 'i8');
    expect((i8.order, i8.time), (0, null));
    expect(repo.isDemo, isTrue);
  });
}
