// Test automatici dell'editor degli alloggi (creazione e modifica).
// Casi, ad esempio: "Google place fills name, address, city, country", "invalid link is explained".

import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/models/trip_destination.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_booking_platform.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

class FakePlaces implements DestinationPlacesService {
  @override
  Future<List<DestinationPrediction>> search(String query,
      {required String languageCode}) async => [
    DestinationPrediction.fromMap({
      'placeId': 'ChIJ-kyoto', 'primaryText': 'Hotel Granvia',
      'secondaryText': 'Kyoto, Giappone', 'fullText': 'Hotel Granvia, Kyoto',
    }),
  ];

  @override
  Future<TripDestination> getDetails(String placeId,
      {required String languageCode}) async => const TripDestination(
    placeId: 'ChIJ-kyoto', displayName: 'Hotel Granvia Kyoto',
    formattedAddress: 'Karasuma 901, Kyoto', latitude: 34.98,
    longitude: 135.75, country: 'Giappone', locality: 'Kyoto',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> openNew(WidgetTester tester, FakeTripStaysRepository repo) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(staysTestApp(
    const TripHotelsPage(tripId: 't1'),
    stays: const [], repository: repo,
    extra: [tripStaysPlacesProvider.overrideWithValue(FakePlaces())]));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('stays-add')));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('stay-save')));
  await tester.tap(find.byKey(const Key('stay-save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a name is enough to create a stay (to confirm, today)',
      (tester) async {
    final repo = FakeTripStaysRepository();
    await openNew(tester, repo);
    expect(find.text('Nuovo alloggio'), findsOneWidget);

    await save(tester);
    expect(find.text('Scrivi il nome dell\'alloggio.'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.enterText(find.byKey(const Key('stay-name')), 'Ryokan');
    await save(tester);
    final stay = repo.created.single;
    expect(stay.name, 'Ryokan');
    expect(stay.createdByUid, 'anna');
    expect(stay.status, TripStayStatus.toConfirm);
    expect(stay.nights, 1);
    expect(find.text('Alloggio salvato.'), findsOneWidget);
  });

  testWidgets('Google place fills name, address, city, country', (tester) async {
    final repo = FakeTripStaysRepository();
    await openNew(tester, repo);
    await tester.enterText(find.byKey(const Key('stay-search')), 'granvia');
    await tester.tap(find.byKey(const Key('stay-search-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    expect(find.text('Luogo collegato a Google Maps'), findsOneWidget);

    await save(tester);
    final stay = repo.created.single;
    expect(stay.name, 'Hotel Granvia Kyoto');
    expect(stay.address, 'Karasuma 901, Kyoto');
    expect(stay.city, 'Kyoto');
    expect(stay.country, 'Giappone');
    expect(stay.googlePlaceId, 'ChIJ-kyoto');
    expect(stay.latitude, 34.98);
  });

  testWidgets('booking: other needs text, invalid link is explained',
      (tester) async {
    final repo = FakeTripStaysRepository();
    await openNew(tester, repo);
    await tester.enterText(find.byKey(const Key('stay-name')), 'Casa');
    await tester.ensureVisible(find.byKey(const Key('stay-booked-via')));
    await tester.tap(find.byKey(const Key('stay-booked-via')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Altro').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('stay-booking-url')), 'booking.com');
    await tester.pumpAndSettle();
    expect(find.text(
      'Il link deve iniziare con http:// o https:// e non contenere spazi.'),
      findsWidgets);
    await save(tester);
    expect(find.text('Scrivi dove è stato prenotato.'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.enterText(find.byKey(const Key('stay-booked-via-other')), 'Expedia');
    await tester.enterText(find.byKey(const Key('stay-booking-url')),
        'https://www.expedia.it/x');
    await tester.enterText(find.byKey(const Key('stay-code')), 'ABC123');
    await tester.ensureVisible(find.byKey(const Key('stay-guest-bruno')));
    await tester.tap(find.byKey(const Key('stay-guest-bruno')));
    await tester.pumpAndSettle();
    await save(tester);
    final stay = repo.created.single;
    expect(stay.bookedVia, TripStayBookingPlatform.other);
    expect(stay.bookedViaOther, 'Expedia');
    expect(stay.bookingUrl, 'https://www.expedia.it/x');
    expect(stay.confirmationCode, 'ABC123');
    expect(stay.guestUids, ['bruno']);
  });

  testWidgets('editing keeps id and author, changes the status', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeTripStaysRepository(uid: 'bruno');
    await tester.pumpWidget(staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: [testStay('s1', createdBy: 'anna', status: TripStayStatus.toConfirm)],
      repository: repo,
      extra: [tripStaysPlacesProvider.overrideWithValue(FakePlaces())]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stay-menu-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica alloggio'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('stay-status-booked')));
    await tester.tap(find.byKey(const Key('stay-status-booked')));
    await save(tester);
    final stay = repo.updated.single;
    expect(stay.id, 's1');
    expect(stay.createdByUid, 'anna');
    expect(stay.status, TripStayStatus.booked);
    expect(stay.checkInTime, '15:00');
  });

  testWidgets('a failed save keeps the editor open with a message',
      (tester) async {
    final repo = FakeTripStaysRepository()..failSave = true;
    await openNew(tester, repo);
    await tester.enterText(find.byKey(const Key('stay-name')), 'Ryokan');
    await save(tester);
    expect(find.text(
      'Impossibile salvare l\'alloggio. Controlla la connessione e riprova.'),
      findsOneWidget);
    expect(find.text('Nuovo alloggio'), findsOneWidget);
  });
}
