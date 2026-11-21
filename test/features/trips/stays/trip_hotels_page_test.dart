// Test automatici della pagina Hotel/Alloggi: elenco, card, avviso di
// sovrapposizione ed eliminazione.
// Casi, ad esempio: "empty state", "only the creator or the owner can delete".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support/fake_trip_stays.dart';

void main() {
  testWidgets('empty state', (tester) async {
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: const [], repository: FakeTripStaysRepository()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stays-empty')), findsOneWidget);
    expect(find.text('Nessun alloggio per ora'), findsOneWidget);
  });

  testWidgets('stays are ordered by check-in', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [
        testStay('b', name: 'Ryokan Osaka', day: 20),
        testStay('a', name: 'Hotel Tokyo', day: 2),
      ],
      repository: FakeTripStaysRepository()));
    await tester.pumpAndSettle();
    final tokyo = tester.getTopLeft(find.text('Hotel Tokyo')).dy;
    final osaka = tester.getTopLeft(find.text('Ryokan Osaka')).dy;
    expect(tokyo, lessThan(osaka));
  });

  testWidgets('card shows status, dates, nights, place, guests and links',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final launch = FakeLaunch();
    await tester.pumpWidget(staysTestApp(
      TripHotelsPage(tripId: 't1', launch: launch.call),
      stays: [testStay('s1',
        bookingUrl: 'https://www.booking.com/h/1',
        propertyUrl: 'https://hotel.example.jp', placeId: 'ChIJ1',
        guests: ['anna', 'carla'], type: TripStayType.apartment)],
      repository: FakeTripStaysRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Prenotato'), findsOneWidget);
    expect(find.text('Appartamento'), findsOneWidget);
    expect(find.text('3 notti'), findsOneWidget);
    expect(find.textContaining('15:00'), findsOneWidget);
    expect(find.text('Kyoto, Giappone'), findsOneWidget);
    expect(find.text('Ospiti: Anna, Ex viaggiatore'), findsOneWidget);
    expect(find.text('Prenotazione'), findsOneWidget);
    expect(find.text('Sito dell\'alloggio'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stay-link-booking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stay-map')));
    await tester.pumpAndSettle();
    expect(launch.calls.first.$1.toString(), 'https://www.booking.com/h/1');
    expect(launch.calls.first.$2, LaunchMode.externalApplication);
    expect(launch.calls.last.$1.queryParameters['query_place_id'], 'ChIJ1');
    expect(launch.calls.last.$2, LaunchMode.platformDefault);
  });

  testWidgets('overlap warning only for active stays', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [
        testStay('a', name: 'Hotel A', day: 10, nights: 4),
        testStay('b', name: 'Hotel B', day: 12, nights: 2),
        testStay('c', name: 'Hotel C', day: 11, nights: 2,
            status: TripStayStatus.cancelled),
      ],
      repository: FakeTripStaysRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Hotel A e Hotel B si sovrappongono nelle date.'),
        findsOneWidget);
    expect(find.textContaining('Hotel C si sovrappongono'), findsNothing);
    expect(find.text('Annullato'), findsOneWidget);
  });

  testWidgets('only the creator or the owner can delete, with confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeTripStaysRepository(uid: 'bruno');
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [
        testStay('mine', name: 'Mio', createdBy: 'bruno'),
        testStay('theirs', name: 'Altro', day: 20, createdBy: 'anna'),
      ],
      repository: repository, ownerUid: 'anna'));
    await tester.pumpAndSettle();

    // Any member may edit, but only the creator or the owner may delete.
    await tester.tap(find.byKey(const Key('stay-menu-theirs')));
    await tester.pumpAndSettle();
    expect(find.text('Modifica'), findsOneWidget);
    expect(find.text('Elimina'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stay-menu-mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare questo alloggio?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stay-delete-confirm')));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['mine']);
    expect(find.text('Alloggio eliminato.'), findsOneWidget);
  });

  testWidgets('the owner can delete any stay', (tester) async {
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [testStay('theirs', createdBy: 'bruno')],
      repository: FakeTripStaysRepository(uid: 'anna'), ownerUid: 'anna'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-menu-theirs')), findsOneWidget);
  });

  testWidgets('narrow screen: no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [testStay('s1', name: 'Un nome di hotel molto lungo a Kyoto',
        bookingUrl: 'https://www.booking.com/h/1',
        propertyUrl: 'https://hotel.example.jp', placeId: 'p',
        guests: ['anna', 'bruno'])],
      repository: FakeTripStaysRepository(), locale: 'en'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('3 nights'), findsOneWidget);
  });
}
