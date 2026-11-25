// Test della Mappa con i dati veri (solo lettura): la lettura usa gli store
// delle sezioni e la lettura condivisa della bucket list; trasporti con
// partenza e arrivo, annullati esclusi, elementi senza posizione contati;
// pagina con il contatore, filtro per giorno (elementi senza giorno
// attenuati), riquadro e 130 % su telefono e schermo largo.

import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_item_type.dart';
import 'package:amaterasutrip/features/trips/bucket_list/models/bucket_list_item.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_canvas.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_screen.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_sources.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/data/trip_bucket_reader.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart';

const kyoto = TripSectionPlace(
  name: 'Stazione',
  latitude: 34.98,
  longitude: 135.75,
);
const tokyo = TripSectionPlace(
  name: 'Haneda',
  latitude: 35.55,
  longitude: 139.78,
);
final day1 = DateTime(2027, 4, 10);

class _Stays extends FakeTripStaysRepository {
  @override
  Stream<List<TripStay>> watch(String tripId) => Stream.value([
    TripStay(
      id: 's1',
      tripId: 't1',
      name: 'Ryokan',
      checkInDate: day1,
      checkOutDate: day1.add(const Duration(days: 2)),
      createdByUid: 'anna',
      latitude: 35.0,
      longitude: 135.77,
      city: 'Kyoto',
    ),
    // No position: counted, not shown.
    TripStay(
      id: 's2',
      tripId: 't1',
      name: 'Senza mappa',
      checkInDate: day1,
      checkOutDate: day1,
      createdByUid: 'anna',
    ),
  ]);
}

List<Override> sources() => [
  tripStaysRepositoryProvider.overrideWithValue(_Stays()),
  tripTransportsStoreProvider.overrideWithValue(
    FakeSectionStore<TripTransport>(
      items: [
        TripTransport(
          id: 't',
          tripId: 't1',
          createdByUid: 'anna',
          type: TripTransportType.flight,
          departureDate: day1,
          from: tokyo,
          to: kyoto,
        ),
        TripTransport(
          id: 'x',
          tripId: 't1',
          createdByUid: 'anna',
          type: TripTransportType.bus,
          departureDate: day1,
          from: tokyo,
          status: TripBookingStatus.cancelled,
        ),
      ],
    ),
  ),
  tripReservationsStoreProvider.overrideWithValue(
    FakeSectionStore<TripReservation>(),
  ),
  tripRestaurantsStoreProvider.overrideWithValue(
    FakeSectionStore<TripRestaurant>(),
  ),
  tripSavedPlacesStoreProvider.overrideWithValue(
    FakeSectionStore<TripSavedPlace>(
      items: const [
        TripSavedPlace(
          id: 'p',
          tripId: 't1',
          createdByUid: 'bruno',
          name: 'Kinkaku-ji',
          category: TripSavedPlaceCategory.sight,
          place: TripSectionPlace(
            name: 'Kinkaku-ji',
            latitude: 35.03,
            longitude: 135.72,
          ),
        ),
      ],
    ),
  ),
  tripBucketReaderProvider.overrideWithValue(
    (id) async => [
      BucketListItem(
        id: 'b',
        tripId: 't1',
        name: 'Nishiki',
        city: 'Kyoto',
        country: 'Giappone',
        type: BucketItemType.attraction,
        createdByUid: 'bruno',
        createdAt: day1,
        updatedAt: day1,
        latitude: 35.005,
        longitude: 135.76,
      ),
    ],
  ),
];

Widget fakeCanvas(
  List<TripMapPoint> points,
  List<List<TripMapPoint>> routes,
  ValueChanged<TripMapPoint> onSelect,
  Set<String> dimmed,
) => ListView(
  padding: const EdgeInsets.only(top: 80),
  children: [
    for (final p in points)
      TextButton(
        key: Key('pin-${p.id}${dimmed.contains(p.id) ? '-dim' : ''}'),
        onPressed: () => onSelect(p),
        child: Text(p.title),
      ),
  ],
);

void main() {
  test('reads every section; transport from and to; cancelled out', () async {
    final c = ProviderContainer(overrides: sources());
    addTearDown(c.dispose);
    final d = await c.read(tripMapLoaderProvider)('t1');
    expect(
      d.points.map((p) => p.id),
      containsAll([
        'stay-s1',
        'transport-t-from',
        'transport-t-to',
        'place-p',
        'bucket-b',
      ]),
    );
    expect(d.points.where((p) => p.refId == 'x'), isEmpty);
    expect(d.withoutPosition, 1);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('page at 130% (width $width): count, day filter, panel', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      bigWindow(tester, width: width);
      await tester.pumpWidget(
        sectionsTestApp(
          const TripMapScreen(tripId: 't1'),
          overrides: [
            ...sources(),
            tripMapCanvasProvider.overrideWithValue(fakeCanvas),
            tripProvider('t1').overrideWith(
              (ref) => Stream.value(
                Trip(
                  id: 't1',
                  name: 'Giappone',
                  destination: 'Kyoto',
                  startDate: day1,
                  endDate: day1.add(const Duration(days: 3)),
                  currency: 'EUR',
                  ownerUid: 'anna',
                  status: TripStatus.active,
                  createdAt: null,
                  updatedAt: null,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 luoghi · 1 senza posizione'), findsOneWidget);
      expect(find.textContaining('Bozza'), findsNothing);
      await tapKey(tester, 'itinerary-filters');
      await tapKey(tester, 'itinerary-filter-day-10');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      // The place and the bucket activity have no day: dimmed.
      expect(find.byKey(const Key('pin-place-p-dim')), findsOneWidget);
      expect(find.byKey(const Key('pin-stay-s1')), findsOneWidget);
      await tapKey(tester, 'pin-stay-s1');
      expect(find.byKey(const Key('map-open-section')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
