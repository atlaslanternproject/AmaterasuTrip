// Test automatici di filtri e ordinamento degli alloggi.
// Casi, ad esempio: "upcoming includes the stay that ends today", "no match shows a dedicated empty state".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/hotels/trip_hotels_page.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_trip_stays.dart';

// April 2027: a (2-5), b (10-12), c (20-21, cancelled, B&B).
final _stays = [
  testStay(
    'c',
    name: 'Casa C',
    day: 20,
    nights: 1,
    status: TripStayStatus.cancelled,
    type: TripStayType.bnb,
  ),
  testStay('a', name: 'Hotel A', day: 2, nights: 3, type: TripStayType.hotel),
  testStay('b', name: 'Ostello B', day: 10, nights: 2),
];
final _today = DateTime(2027, 4, 12, 18, 30);

List<String> ids(TripStaysFilter filter) =>
    filter.apply(_stays, _today).map((s) => s.id).toList();

Future<void> openPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    staysTestApp(
      TripHotelsPage(tripId: 't1', today: _today),
      stays: _stays,
      repository: FakeTripStaysRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pick(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  test('default: all stays by check-in, nothing active', () {
    const filter = TripStaysFilter();
    expect(ids(filter), ['a', 'b', 'c']);
    expect(filter.isActive, isFalse);
    expect(ids(filter.copyWith(sort: TripStaysSort.checkInDesc)), [
      'c',
      'b',
      'a',
    ]);
  });

  test('upcoming includes the stay that ends today', () {
    expect(ids(const TripStaysFilter(when: TripStaysWhen.upcoming)), [
      'b',
      'c',
    ]);
    expect(ids(const TripStaysFilter(when: TripStaysWhen.past)), ['a']);
  });

  test('status and type; stays without a type are left out', () {
    expect(ids(const TripStaysFilter(statuses: {TripStayStatus.cancelled})), [
      'c',
    ]);
    expect(
      ids(const TripStaysFilter(types: {TripStayType.hotel, TripStayType.bnb})),
      ['a', 'c'],
    );
    const all = TripStaysFilter(
      statuses: {TripStayStatus.booked},
      types: {TripStayType.hotel},
      when: TripStaysWhen.past,
      sort: TripStaysSort.checkInDesc,
    );
    expect(all.activeCount, 3);
    expect(all.cleared().isActive, isFalse);
    expect(all.cleared().sort, TripStaysSort.checkInDesc);
  });

  testWidgets('filters: indicator, count, clear', (tester) async {
    await openPage(tester);
    expect(find.text('Filtri'), findsOneWidget);
    expect(find.byKey(const Key('stays-filters-clear')), findsNothing);

    await pick(tester, 'stays-filters');
    await pick(tester, 'stays-when-upcoming');
    await pick(tester, 'stays-filter-status-booked');
    await pick(tester, 'stays-sheet-done');
    expect(find.text('Filtri (2)'), findsOneWidget);
    expect(find.text('1 di 3'), findsOneWidget);
    expect(find.text('Ostello B'), findsOneWidget);
    expect(find.text('Hotel A'), findsNothing);

    await pick(tester, 'stays-filters-clear');
    expect(find.text('Filtri'), findsOneWidget);
    expect(find.text('Hotel A'), findsOneWidget);
  });

  testWidgets('no match shows a dedicated empty state', (tester) async {
    await openPage(tester);
    await pick(tester, 'stays-filters');
    await pick(tester, 'stays-when-past');
    await pick(tester, 'stays-filter-type-camping');
    await pick(tester, 'stays-sheet-done');
    expect(find.byKey(const Key('stays-no-match')), findsOneWidget);
    expect(find.text('Nessun alloggio con questi filtri'), findsOneWidget);
    expect(find.byKey(const Key('stays-empty')), findsNothing);

    await pick(tester, 'stays-no-match-clear');
    expect(find.byKey(const Key('stays-no-match')), findsNothing);
    expect(find.text('Casa C'), findsOneWidget);
  });

  testWidgets('order by date, newest first', (tester) async {
    await openPage(tester);
    await pick(tester, 'stays-filters');
    await pick(tester, 'stays-sort-checkInDesc');
    await pick(tester, 'stays-sheet-done');
    final c = tester.getTopLeft(find.text('Casa C')).dy;
    final a = tester.getTopLeft(find.text('Hotel A')).dy;
    expect(c, lessThan(a));
    expect(find.text('Check-in: dal più lontano'), findsOneWidget);
    expect(find.text('Filtri'), findsOneWidget);
  });
}
