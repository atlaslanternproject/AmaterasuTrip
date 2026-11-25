// Test delle schermate della bozza con i dati di esempio: etichetta
// "Bozza", linea del tempo con giorni e gruppi per zona, avviso di
// sovrapposizione, "previsto / fatto", filtri condivisi, giorno per
// giorno con riordino, eliminazione con doppia conferma, vista mappa con
// riquadro, pagina Mappa con tutti i luoghi, 130 % su telefono e largo.

import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_demo.dart';
import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_repository.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_screen.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_canvas.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_screen.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_recent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

/// Maps do not draw in tests: one button per pin.
Widget fakeCanvas(
  List<TripItineraryItem> points,
  List<List<TripItineraryItem>> routes,
  ValueChanged<TripItineraryItem> onSelect,
) => ListView(
  key: const Key('fake-map'),
  children: [
    for (final p in points)
      TextButton(
        key: Key('pin-${p.id}'),
        onPressed: () => onSelect(p),
        child: Text(p.title),
      ),
  ],
);

Future<void> open(
  WidgetTester tester,
  Widget page, {
  double width = 1000,
}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  await tester.pumpWidget(
    sectionsTestApp(
      page,
      overrides: [
        tripItineraryRepositoryProvider.overrideWithValue(
          DemoTripItineraryRepository(),
        ),
        tripMapCanvasProvider.overrideWithValue(fakeCanvas),
        tripSearchUidProvider.overrideWithValue('demo-yato'),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('timeline: draft label, days, zones, notices', (tester) async {
    await open(tester, const TripItineraryScreen(tripId: 't1'));
    expect(find.byKey(const Key('draft-label')), findsOneWidget);
    expect(find.text('Bozza: dati di esempio, non si salva'), findsOneWidget);
    expect(find.byKey(const Key('itinerary-day-1')), findsOneWidget);
    final list = find.descendant(
      of: find.byKey(const Key('itinerary-timeline')),
      matching: find.byType(Scrollable),
    );
    // Day 4 is further down: the list builds it while scrolling.
    await tester.scrollUntilVisible(
      find.byKey(const Key('itinerary-day-4')),
      400,
      scrollable: list,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('itinerary-day-1')),
      -400,
      scrollable: list,
    );
    expect(find.text('Arashiyama'), findsOneWidget);
    expect(find.text('Senza zona'), findsWidgets);
    expect(find.byKey(const Key('itinerary-overlap-i6')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-actual-i8')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-leg-i6')), findsOneWidget);
  });

  testWidgets('filters with the shared sheet', (tester) async {
    await open(tester, const TripItineraryScreen(tripId: 't1'));
    await tapKey(tester, 'itinerary-filters');
    await tapKey(tester, 'itinerary-filter-section-bucketList');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itinerary-item-i9')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-item-i2')), findsNothing);
  });

  testWidgets('day by day: strip, reorder, delete twice confirmed', (
    tester,
  ) async {
    await open(tester, const TripItineraryScreen(tripId: 't1'));
    await tapKey(tester, 'itinerary-view-day');
    expect(find.byKey(const Key('itinerary-day-strip')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-item-i2')), findsOneWidget);
    await tapKey(tester, 'itinerary-reorder');
    expect(find.byKey(const Key('itinerary-reorder-list')), findsOneWidget);
    await tapKey(tester, 'itinerary-reorder');
    await tapKey(tester, 'itinerary-delete-i5');
    await tapKey(tester, 'itinerary-delete-ok');
    await tapKey(tester, 'itinerary-delete-ok');
    expect(find.byKey(const Key('itinerary-item-i5')), findsNothing);
  });

  testWidgets('itinerary map view and panel', (tester) async {
    await open(tester, const TripItineraryScreen(tripId: 't1'));
    await tapKey(tester, 'itinerary-view-map');
    await tapKey(tester, 'pin-i7');
    expect(find.byKey(const Key('map-panel')), findsOneWidget);
    expect(find.byKey(const Key('map-open-section')), findsOneWidget);
    expect(find.byKey(const Key('map-open-maps')), findsOneWidget);
  });

  testWidgets('map page: every place, also outside the itinerary', (
    tester,
  ) async {
    await open(tester, const TripMapScreen(tripId: 't1'));
    expect(find.text('16 luoghi'), findsOneWidget);
    await tapKey(tester, 'pin-c1');
    expect(find.text('Kinkaku-ji'), findsWidgets);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('130% at width $width without overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, const TripItineraryScreen(tripId: 't1'), width: width);
      await tapKey(tester, 'itinerary-view-day');
      await open(tester, const TripMapScreen(tripId: 't1'), width: width);
      await tapKey(tester, 'pin-i2');
      expect(tester.takeException(), isNull);
    });
  }
}
