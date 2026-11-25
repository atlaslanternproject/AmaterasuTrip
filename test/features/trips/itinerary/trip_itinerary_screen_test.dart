// Test della pagina Itinerario con i dati veri (store finto delle sezioni):
// stato vuoto con l'invito ad aggiungere, nessuna etichetta "Bozza", linea
// del tempo con zone, avvisi e "fatto invece", dati aggiornati degli
// elementi collegati, filtri, cestino solo per autore o proprietario con
// doppia conferma, "+" con la scelta e "Cerca" nella sezione, giorni solo
// dalle date del viaggio ("Fuori dalle date", invito senza date), vista
// mappa, 130 %.

import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_repository.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_item.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_add_search.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_screen.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_canvas.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_sources.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_recent.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import 'support/itinerary_fixtures.dart';

/// Maps do not draw in tests: one button per pin.
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
        key: Key('pin-${p.id}'),
        onPressed: () => onSelect(p),
        child: Text(p.title),
      ),
  ],
);

Future<FakeSectionStore<TripItineraryItem>> open(
  WidgetTester tester, {
  List<TripItineraryItem>? items,
  double width = 1000,
  DateTime? start,
  DateTime? end,
}) async {
  SharedPreferences.setMockInitialValues({});
  bigWindow(tester, width: width);
  final store = FakeSectionStore<TripItineraryItem>(
    items: items ?? itineraryItems,
  );
  await tester.pumpWidget(
    sectionsTestApp(
      const TripItineraryScreen(tripId: 't1'),
      overrides: [
        tripItineraryStoreProvider.overrideWithValue(store),
        tripMapLoaderProvider.overrideWithValue(
          (id) async => (
            points: const <TripMapPoint>[],
            withoutPosition: 0,
            catalog: itineraryCatalog,
          ),
        ),
        tripMapCanvasProvider.overrideWithValue(fakeCanvas),
        tripSearchUidProvider.overrideWithValue('anna'),
        tripProvider('t1').overrideWith(
          (ref) => Stream.value(
            Trip(
              id: 't1',
              name: 'Giappone',
              destination: 'Kyoto',
              startDate: start ?? itineraryStart,
              endDate: end ?? itineraryDay(2),
              currency: 'EUR',
              ownerUid: 'owner',
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
  return store;
}

void main() {
  testWidgets('empty itinerary: common empty state with the invitation', (
    tester,
  ) async {
    await open(tester, items: const []);
    expect(find.byKey(const Key('itinerary-empty')), findsOneWidget);
    expect(find.textContaining('lo costruisci tu'), findsOneWidget);
    expect(find.textContaining('Bozza'), findsNothing);
  });

  testWidgets('timeline: zones, notices, done instead, live data', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('itinerary-day-1')), findsOneWidget);
    expect(find.text('Gion'), findsOneWidget);
    expect(find.byKey(const Key('itinerary-overlap-i6')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-actual-i8')), findsOneWidget);
    // Linked reservation: name and status from its section.
    // (also in the overlap notice and the leg between the two items)
    expect(find.textContaining('Tenryū-ji (biglietto)'), findsWidgets);
    expect(find.text('Tenryū-ji'), findsNothing);
    expect(find.byKey(const Key('itinerary-leg-i6')), findsOneWidget);
  });

  testWidgets('bin only for the author or owner, double confirmation', (
    tester,
  ) async {
    final store = await open(tester);
    expect(find.byKey(const Key('itinerary-delete-i3')), findsNothing);
    await tapKey(tester, 'itinerary-delete-i4');
    await tapKey(tester, 'itinerary-delete-ok');
    await tapKey(tester, 'itinerary-delete-ok');
    expect(store.deleted.single.id, 'i4');
  });

  testWidgets('add a free item: the title is required, author is me', (
    tester,
  ) async {
    final store = await open(tester, items: const []);
    await tapKey(tester, 'itinerary-add');
    await tapKey(tester, 'itinerary-add-free');
    final save = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('itinerary-edit-save')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(save.onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('itinerary-edit-title')),
      'Cena a Pontocho',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'itinerary-edit-save');
    expect(store.created.single.title, 'Cena a Pontocho');
    expect(store.created.single.createdByUid, 'anna');
  });

  testWidgets('"+": choose a section, then search its elements', (
    tester,
  ) async {
    final store = await open(tester);
    await tapKey(tester, 'itinerary-add');
    await tapKey(tester, 'itinerary-add-section-reservations');
    // Already linked (i7): still listed, with the note.
    expect(find.text("Già nell'itinerario"), findsOneWidget);
    await tester.enterText(find.byKey(const Key('itinerary-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itinerary-search-none')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('itinerary-search')), 'tenr');
    await tester.pumpAndSettle();
    await tapKey(tester, 'itinerary-add-existing-ref-i7');
    await tapKey(tester, 'itinerary-edit-save');
    final added = store.created.single;
    expect(added.kind, TripItineraryKind.ref);
    expect(added.refId, 'ref-i7');
    expect(added.createdByUid, 'anna');
  });

  testWidgets('search: elements not yet in the itinerary first', (
    tester,
  ) async {
    final found = tripItinerarySearch(
      [
        ...itineraryCatalog,
        const TripItineraryRef(
          section: TripSearchSection.reservations,
          refId: 'new',
          title: 'Zen tour',
        ),
      ],
      TripSearchSection.reservations,
      '',
      {'reservations/ref-i7'},
    );
    expect(found.map((c) => c.refId), ['new', 'ref-i7']);
  });

  testWidgets('days come from the trip: items outside go in their group', (
    tester,
  ) async {
    // The trip now ends on day 1: the free day (day 2) is outside.
    await open(tester, end: itineraryDay(1));
    expect(find.byKey(const Key('itinerary-outside')), findsOneWidget);
    await tapKey(tester, 'itinerary-view-day');
    await tapKey(tester, 'itinerary-strip-outside');
    expect(find.byKey(const Key('itinerary-item-i9')), findsOneWidget);
  });

  testWidgets('trip without dates: invitation to set them', (tester) async {
    final zero = DateTime.fromMillisecondsSinceEpoch(0);
    await open(tester, start: zero, end: zero);
    expect(find.byKey(const Key('itinerary-dates-empty')), findsOneWidget);
    expect(find.textContaining('non ha ancora le date'), findsOneWidget);
  });

  testWidgets('filters and the map view with its panel', (tester) async {
    await open(tester);
    await tapKey(tester, 'itinerary-filters');
    await tapKey(tester, 'itinerary-filter-section-stays');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('itinerary-item-i2')), findsOneWidget);
    expect(find.byKey(const Key('itinerary-item-i3')), findsNothing);
    await tapKey(tester, 'itinerary-view-map');
    await tapKey(tester, 'pin-i2');
    expect(find.byKey(const Key('map-panel')), findsOneWidget);
  });

  for (final width in [390.0, 1300.0]) {
    testWidgets('130% at width $width without overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, width: width);
      await tapKey(tester, 'itinerary-view-day');
      expect(tester.takeException(), isNull);
    });
  }
}
