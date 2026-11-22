// Test automatici delle azioni degli alloggi in tutte le viste: Mappa,
// Spesa (crea/collega/vedi), Contatta (solo con un contatto) e Modifica,
// come icone con suggerimento nelle viste Elenco e Dettagli.
// Casi, ad esempio: "Elenco: every action is reachable", "Dettagli: linked expense opens Vedi spesa".

import 'package:amaterasutrip/features/trips/budget/presentation/budget_expense_details_dialog.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support/fake_trip_stays.dart';

final _stays = [
  testStay('s1', placeId: 'ChIJ1', phone: '+81 75 344'),
  testStay('s2', name: 'Ryokan', day: 20, expenseId: 'e-hotel'),
];

final _budget = FakeBudgetApi(
  uid: 'anna',
  shared: [
    FakeDoc('e-hotel', {
      'title': 'Ryokan',
      'snapshot': {
        'total': eur(36000),
        'status': 'paid',
        'shares': {'anna': eur(36000)},
        'advances': {'anna': eur(36000)},
      },
      'participantUids': ['anna'],
      'participantNames': {'anna': 'Anna'},
      'category': 'accommodation',
    }),
  ],
);

Future<FakeLaunch> openIn(WidgetTester tester, String view) async {
  SharedPreferences.setMockInitialValues({
    'amaterasu.stays.v1.anna.t1.view': view,
  });
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final launch = FakeLaunch();
  await tester.pumpWidget(
    staysTestApp(
      TripHotelsPage(tripId: 't1', launch: launch.call),
      stays: _stays,
      repository: FakeTripStaysRepository(),
      budget: _budget,
    ),
  );
  await tester.pumpAndSettle();
  return launch;
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Card: Mappa, Spesa, Contatta and Modifica are visible', (
    tester,
  ) async {
    await openIn(tester, 'cards');
    for (final key in [
      'stay-map',
      'stay-contact',
      'stay-expense-create-s1',
      'stay-edit-s1',
      'stay-edit-s2',
      'stay-expense-view-s2',
    ]) {
      expect(find.byKey(Key(key)), findsWidgets, reason: key);
    }
  });

  for (final view in ['list', 'details']) {
    testWidgets('$view: every action is reachable as an icon with tooltip', (
      tester,
    ) async {
      final launch = await openIn(tester, view);
      for (final key in [
        'stay-quick-map-s1',
        'stay-quick-expense-s1',
        'stay-quick-contact-s1',
        'stay-quick-edit-s1',
        'stay-quick-expense-s2',
        'stay-quick-edit-s2',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      // Contatta only with at least one contact; no Google place, no map.
      expect(find.byKey(const Key('stay-quick-contact-s2')), findsNothing);
      expect(find.byKey(const Key('stay-quick-map-s2')), findsNothing);
      expect(find.byTooltip('Contatta'), findsOneWidget);
      expect(find.byTooltip('Modifica'), findsNWidgets(2));

      await tap(tester, 'stay-quick-map-s1');
      expect(launch.calls.single.$1.queryParameters['query_place_id'], 'ChIJ1');
      expect(launch.calls.single.$2, LaunchMode.platformDefault);

      await tap(tester, 'stay-quick-contact-s1');
      expect(find.text('Contatta Hotel Kyoto'), findsOneWidget);
      await tap(tester, 'stay-contact-phone-copy');
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();

      await tap(tester, 'stay-quick-expense-s1');
      expect(find.text('Crea spesa'), findsOneWidget);
      expect(find.text('Collega spesa esistente'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tap(tester, 'stay-quick-expense-s2');
      expect(find.byType(BudgetExpenseDetailsDialog), findsOneWidget);
      Navigator.of(
        tester.element(find.byType(BudgetExpenseDetailsDialog)),
      ).pop();
      await tester.pumpAndSettle();

      await tap(tester, 'stay-quick-edit-s2');
      expect(find.text('Modifica alloggio'), findsOneWidget);
    });
  }
}
