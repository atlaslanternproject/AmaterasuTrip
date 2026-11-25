// Test automatici delle sezioni "Costo e cancellazione" e "Servizi e come
// arrivare" dell'editor degli alloggi (1.15.0).
// Casi, ad esempio: "new stay with cost in the trip currency", "invalid cost is explained".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_amenity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

Future<void> open(
  WidgetTester tester,
  FakeTripStaysRepository repo, {
  List<TripStay> stays = const [],
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    staysTestApp(
      const TripHotelsPage(tripId: 't1'),
      stays: stays,
      repository: repo,
      tripInfo: (
        currency: 'JPY',
        start: DateTime(2027, 4, 10),
        end: DateTime(2027, 4, 20),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final key = stays.isEmpty ? 'stays-add' : 'stay-edit-${stays.first.id}';
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new stay with cost in the trip currency, services and directions',
    (tester) async {
      final repo = FakeTripStaysRepository();
      await open(tester, repo);
      await tester.enterText(find.byKey(const Key('stay-name')), 'Ryokan');
      // Cost and city tax both start in the trip currency.
      expect(find.text('JPY'), findsNWidgets(2));
      await tester.enterText(find.byKey(const Key('stay-cost')), '32000');
      await tapKey(tester, 'stay-amenity-breakfast');
      await tapKey(tester, 'stay-amenity-wifi');
      await tester.enterText(
        find.byKey(const Key('stay-directions')),
        'Linea Karasuma, uscita 5',
      );
      await tapKey(tester, 'stay-cancellation-day');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'stay-save');

      final stay = repo.created.single;
      expect(stay.estimatedCostMinorUnits, 32000);
      expect(stay.estimatedCostCurrency, 'JPY');
      expect(stay.amenities, [TripStayAmenity.breakfast, TripStayAmenity.wifi]);
      expect(stay.directions, 'Linea Karasuma, uscita 5');
      expect(stay.freeCancellationUntil, isNotNull);
    },
  );

  testWidgets('invalid cost is explained and nothing is saved', (tester) async {
    final repo = FakeTripStaysRepository();
    await open(tester, repo);
    await tester.enterText(find.byKey(const Key('stay-name')), 'Ryokan');
    await tester.enterText(find.byKey(const Key('stay-cost')), '12,5');
    await tapKey(tester, 'stay-save');
    expect(find.textContaining('Costo previsto non valido'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('editing shows the saved values and can remove them', (
    tester,
  ) async {
    final repo = FakeTripStaysRepository();
    final saved = TripStay(
      id: 's1',
      tripId: 't1',
      name: 'Hotel Kyoto',
      checkInDate: DateTime(2027, 4, 12),
      checkOutDate: DateTime(2027, 4, 15),
      createdByUid: 'anna',
      estimatedCostMinorUnits: 45050,
      estimatedCostCurrency: 'EUR',
      freeCancellationUntil: DateTime(2027, 4, 1),
      amenities: const [TripStayAmenity.parking],
      directions: 'Bus 100',
    );
    await open(tester, repo, stays: [saved]);
    expect(find.text('450.50'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('Bus 100'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('stay-cost')), '');
    await tapKey(tester, 'stay-amenity-parking');
    await tapKey(tester, 'stay-cancellation-clear');
    await tester.enterText(find.byKey(const Key('stay-directions')), '');
    await tapKey(tester, 'stay-save');

    final stay = repo.updated.single;
    expect(stay.estimatedCostMinorUnits, isNull);
    expect(stay.estimatedCostCurrency, isNull);
    expect(stay.freeCancellationUntil, isNull);
    expect(stay.amenities, isEmpty);
    expect(stay.directions, isNull);
  });
}
