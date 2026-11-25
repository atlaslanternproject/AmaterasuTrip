// Test automatici del fuso orario per città (Extra C): scarto e ora dei
// fusi fissi, lettura della risposta del geocoding, selettore con ricerca
// finta, trasporto e prenotazione salvati con fuso e città; un trasporto
// vecchio senza città resta come prima ("UTC+01:00").
// Casi, ad esempio: "fixed zones", "transport saves the zone and its offset".

import 'package:amaterasutrip/core/time_zones/amaterasu_zone_clock.dart';
import 'package:amaterasutrip/core/time_zones/amaterasu_zone_search.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/trip_transport_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/trips/sections/support/fake_section_store.dart';

class FakeZoneSearch implements AmaterasuZoneSearch {
  final queries = <String>[];

  @override
  Future<List<AmaterasuZoneCity>> search(String query, String lang) async {
    queries.add(query);
    return const [
      AmaterasuZoneCity(
        name: 'Tokyo',
        zone: 'Etc/GMT-9',
        region: 'Tokyo',
        country: 'Giappone',
      ),
    ];
  }
}

Future<void> pickTokyo(WidgetTester tester, String prefix) async {
  await tapKey(tester, '$prefix-zone');
  await tester.enterText(find.byKey(Key('$prefix-zone-search')), 'tokyo');
  await tapKey(tester, '$prefix-zone-search-go');
  await tapKey(tester, '$prefix-zone-result-0');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fixed zones: offset and local time', () {
    expect(AmaterasuZoneClock.fixedOffset('Etc/GMT-9'), '+09:00');
    expect(AmaterasuZoneClock.fixedOffset('Etc/GMT+5'), '-05:00');
    expect(AmaterasuZoneClock.fixedOffset('Etc/UTC'), '+00:00');
    expect(AmaterasuZoneClock.fixedOffset('Europe/Rome'), isNull);
    expect(
      AmaterasuZoneClock.localTimeNow(
        'Etc/GMT-9',
        now: DateTime.utc(2027, 4, 12, 5, 32),
      ),
      '14:32',
    );
  });

  test('geocoding answer: city, region, country and zone', () {
    final cities = OpenMeteoZoneSearch.parse(
      '{"results":[{"name":"Venezia","admin1":"Veneto","country":"Italia",'
      '"timezone":"Europe/Rome"},{"name":"Senza fuso"}]}',
    );
    expect(cities.single.zone, 'Europe/Rome');
    expect(cities.single.place, 'Veneto, Italia');
    expect(OpenMeteoZoneSearch.parse('{}'), isEmpty);
  });

  testWidgets('transport saves the zone, the city and its offset', (
    tester,
  ) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripTransport>();
    final search = FakeZoneSearch();
    await tester.pumpWidget(
      sectionsTestApp(
        TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [
          tripTransportsStoreProvider.overrideWithValue(store),
          amaterasuZoneSearchProvider.overrideWithValue(search),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'transport-add');
    await pickTokyo(tester, 'transport-arrival');
    expect(search.queries, ['tokyo']);
    await tapKey(tester, 'transport-save');
    final saved = store.created.single;
    expect(saved.extras.arrivalZone, 'Etc/GMT-9');
    expect(saved.extras.arrivalCity, 'Tokyo');
    expect(saved.arrivalOffset, '+09:00');
  });

  testWidgets('an old transport without city looks the same', (tester) async {
    bigWindow(tester);
    final old = TripTransport(
      id: 'a',
      tripId: 't1',
      createdByUid: 'anna',
      type: TripTransportType.train,
      status: TripBookingStatus.booked,
      departureDate: DateTime(2027, 4, 12),
      departureTime: '10:00',
      departureOffset: '+01:00',
    );
    await tester.pumpWidget(
      sectionsTestApp(
        TripTransportPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [
          tripTransportsStoreProvider.overrideWithValue(
            FakeSectionStore<TripTransport>(items: [old]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('(UTC+01:00)'), findsWidgets);
  });

  testWidgets('booking saves the zone and shows the city', (tester) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripReservation>();
    await tester.pumpWidget(
      sectionsTestApp(
        TripBookingsPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [
          tripReservationsStoreProvider.overrideWithValue(store),
          amaterasuZoneSearchProvider.overrideWithValue(FakeZoneSearch()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'reservation-add');
    await tester.enterText(find.byKey(const Key('reservation-name')), 'Museo');
    await pickTokyo(tester, 'reservation');
    await tapKey(tester, 'reservation-save');
    final saved = store.created.single;
    expect((saved.zone, saved.zoneCity), ('Etc/GMT-9', 'Tokyo'));
  });
}
