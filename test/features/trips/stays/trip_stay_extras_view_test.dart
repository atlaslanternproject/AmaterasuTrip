// Test automatici di costo previsto, cancellazione gratuita, servizi e
// "come arrivare" nelle viste degli alloggi, e del costo come valore
// iniziale di "Crea spesa" (1.15.0).
// Casi, ad esempio: "card shows cost, services and directions", "deadline soon uses the warning color".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_create_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_amenity.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_trip_stays.dart';

TripStay stay({
  String id = 's1',
  int? cost,
  String? currency,
  DateTime? until,
  TripStayStatus status = TripStayStatus.booked,
}) => TripStay(
  id: id,
  tripId: 't1',
  name: 'Hotel Kyoto',
  checkInDate: DateTime(2027, 4, 12),
  checkOutDate: DateTime(2027, 4, 15),
  status: status,
  createdByUid: 'anna',
  estimatedCostMinorUnits: cost,
  estimatedCostCurrency: currency,
  freeCancellationUntil: until,
  amenities: const [TripStayAmenity.breakfast, TripStayAmenity.wifi],
  directions: 'Bus 100',
);

Future<void> open(
  WidgetTester tester,
  List<TripStay> stays, {
  DateTime? today,
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    // Pre-existing, visual only warning of the budget create dialog.
    if (!details.exceptionAsString().contains('ListTile background color')) {
      original?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = original);
  await tester.pumpWidget(
    staysTestApp(
      TripHotelsPage(tripId: 't1', today: today ?? DateTime(2027, 3, 1)),
      stays: stays,
      repository: FakeTripStaysRepository(),
      budget: FakeBudgetApi(
        uid: 'anna',
        members: [
          {'uid': 'anna', 'name': 'Anna'},
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('card shows cost, services, directions and the deadline', (
    tester,
  ) async {
    await open(tester, [
      stay(cost: 45050, currency: 'EUR', until: DateTime(2027, 4, 1)),
    ]);
    expect(find.byKey(const Key('stay-cost-line')), findsOneWidget);
    expect(find.textContaining('Costo previsto: '), findsOneWidget);
    expect(find.text('Inclusi: Colazione · Wi-Fi'), findsOneWidget);
    expect(find.text('Come arrivare: Bus 100'), findsOneWidget);
    expect(find.byKey(const Key('stay-cancellation-open-s1')), findsOneWidget);
    expect(
      find.textContaining('Cancellazione gratuita fino al'),
      findsOneWidget,
    );
  });

  testWidgets('deadline soon uses the warning, also in Elenco and Dettagli', (
    tester,
  ) async {
    await open(tester, [
      stay(until: DateTime(2027, 4, 1)),
    ], today: DateTime(2027, 3, 30));
    expect(find.byKey(const Key('stay-cancellation-soon-s1')), findsOneWidget);
    expect(find.textContaining('mancano 2 giorni'), findsOneWidget);
    expect(find.byKey(const Key('stay-cost-line')), findsNothing);

    for (final (view, key) in [
      ('Elenco', 'stay-cancellation-soon-s1'),
      ('Dettagli', 'stay-row-cancellation-s1'),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('stays-view')),
          matching: find.text(view),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key(key)), findsOneWidget, reason: view);
    }
  });

  testWidgets('passed deadline is muted; cancelled stays show none', (
    tester,
  ) async {
    await open(tester, [
      stay(until: DateTime(2027, 4, 1)),
      stay(
        id: 's2',
        until: DateTime(2027, 4, 1),
        status: TripStayStatus.cancelled,
      ),
    ], today: DateTime(2027, 4, 5));
    expect(
      find.byKey(const Key('stay-cancellation-expired-s1')),
      findsOneWidget,
    );
    expect(find.textContaining('scaduta il'), findsOneWidget);
    expect(find.byKey(const Key('stay-cancellation-expired-s2')), findsNothing);
  });

  testWidgets('phone width: long deadline label fits without overflow', (
    tester,
  ) async {
    await open(tester, [
      stay(cost: 45050, currency: 'EUR', until: DateTime(2027, 4, 1)),
    ], today: DateTime(2027, 3, 31));
    tester.view.physicalSize = const Size(340, 2400);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stay-cancellation-soon-s1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final withCost in [true, false]) {
    testWidgets('Crea spesa starts from the expected cost ($withCost)', (
      tester,
    ) async {
      await open(tester, [
        withCost ? stay(cost: 45050, currency: 'USD') : stay(),
      ]);
      await tester.tap(find.byKey(const Key('stay-expense-create-s1')));
      await tester.pumpAndSettle();
      final dialog = tester.widget<BudgetCreateDialog>(
        find.byType(BudgetCreateDialog),
      );
      expect(dialog.initialMinorUnits, withCost ? 45050 : null);
      if (withCost) expect(dialog.currency, 'USD');
    });
  }
}
