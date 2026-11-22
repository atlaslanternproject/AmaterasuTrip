// Test automatici delle modalità di visualizzazione degli alloggi (Card,
// Elenco, Dettagli), come nella bucket list.
// Casi, ad esempio: "the chosen view is remembered per user and trip", "every view fits a phone".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_view_preferences.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_trip_stays.dart';

final _stays = [
  testStay('s1', name: 'Hotel Granvia Kyoto', placeId: 'p1',
      type: TripStayType.hotel, phone: '+81 75 344', expenseId: null),
  testStay('s2', name: 'Ostello', day: 20, nights: 2),
];

Future<void> openPage(WidgetTester tester, {double width = 1000,
    String locale = 'it'}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(staysTestApp(const TripHotelsPage(tripId: 't1'),
      stays: _stays, repository: FakeTripStaysRepository(), locale: locale));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byKey(const Key('stays-view')), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('same names and icons as the bucket list', (tester) async {
    await openPage(tester);
    final selector = tester.widget<SegmentedButton<Object?>>(
        find.byWidgetPredicate((w) => w is SegmentedButton));
    expect(selector.segments.map((s) => (s.label as Text).data),
        ['Card', 'Elenco', 'Dettagli']);
    expect(selector.segments.map((s) => (s.icon as Icon).icon),
        [Icons.grid_view, Icons.view_list, Icons.table_rows]);
  });

  testWidgets('Card: big card with photo on top (default)', (tester) async {
    await openPage(tester);
    expect(find.byKey(const Key('stay-card-s1')), findsOneWidget);
    expect(find.byKey(const Key('stay-dates-s1')), findsOneWidget);
    expect(find.byKey(const Key('stay-compact-s1')), findsNothing);
  });

  testWidgets('Elenco: small photo, name, type, dates and status',
      (tester) async {
    await openPage(tester);
    await choose(tester, 'Elenco');
    final card = find.byKey(const Key('stay-compact-s1'));
    expect(card, findsOneWidget);
    final photo = find.descendant(of: card,
        matching: find.byKey(const Key('stay-photo-placeholder')));
    expect(tester.getSize(photo), const Size(92, 94));
    for (final text in ['Hotel Granvia Kyoto', 'Hotel', 'Prenotato']) {
      expect(find.descendant(of: card, matching: find.text(text)),
          findsOneWidget, reason: text);
    }
    expect(find.descendant(of: card, matching: find.textContaining('3 notti')),
        findsOneWidget);
    expect(find.byKey(const Key('stay-card-s1')), findsNothing);
  });

  testWidgets('Dettagli: one essential row per stay, no photo',
      (tester) async {
    await openPage(tester);
    await choose(tester, 'Dettagli');
    final row = find.byKey(const Key('stay-row-s1'));
    expect(row, findsOneWidget);
    expect(find.byKey(const Key('stay-row-s2')), findsOneWidget);
    expect(find.descendant(of: row,
        matching: find.byKey(const Key('stay-photo-placeholder'))), findsNothing);
    expect(find.descendant(of: row, matching: find.textContaining('Prenotato')),
        findsOneWidget);
    expect(tester.getSize(row).height, lessThan(70));
  });

  testWidgets('the chosen view is remembered per user and trip',
      (tester) async {
    await openPage(tester);
    await choose(tester, 'Dettagli');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TripStaysViewPreferences.key('anna', 't1')),
        'details');

    // Opening the page again starts from the saved view.
    await tester.pumpWidget(const SizedBox());
    await openPage(tester);
    expect(find.byKey(const Key('stay-row-s1')), findsOneWidget);
  });

  for (final view in ['Cards', 'List', 'Details']) {
    testWidgets('every view fits a phone ($view)', (tester) async {
      await openPage(tester, width: 360, locale: 'en');
      await choose(tester, view);
      expect(tester.takeException(), isNull);
    });
  }
}
