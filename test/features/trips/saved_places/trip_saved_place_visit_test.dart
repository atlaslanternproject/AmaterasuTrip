// Test automatici delle aggiunte v2 ai luoghi salvati: priorità, visitato,
// tempo di visita, prezzo d'ingresso, biglietti, zona e giorno; ordine per
// priorità, gruppi per zona e per giorno, filtro "da visitare", editor.
// Casi, ad esempio: "grouped by area with a title per area", "editor saves the visit block".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/saved_places/trip_saved_places_page.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripSavedPlace spot(
  String id, {
  String? priority,
  bool visited = false,
  String? area,
  DateTime? day,
}) => TripSavedPlace(
  id: id,
  tripId: 't1',
  createdByUid: 'anna',
  name: 'Luogo $id',
  category: TripSavedPlaceCategory.sight,
  priority: priority,
  visited: visited,
  area: area,
  plannedDay: day,
);

Future<FakeSectionStore<TripSavedPlace>> open(
  WidgetTester tester,
  List<TripSavedPlace> items,
) async {
  bigWindow(tester);
  final store = FakeSectionStore<TripSavedPlace>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripSavedPlacesPage(tripId: 't1'),
      overrides: [tripSavedPlacesStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('visit fields are saved and checked', () {
    const codec = TripSavedPlaceCodec();
    final item = TripSavedPlace(
      id: 'a',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'Inari',
      category: TripSavedPlaceCategory.sight,
      place: const TripSectionPlace(name: 'Inari'),
      priority: 'SS',
      visited: true,
      visitMinutes: 90,
      ticketsUrl: 'https://inari.jp/t',
      area: 'Higashiyama',
      plannedDay: DateTime(2027, 4, 14),
      entryPriceMinorUnits: 500,
      entryPriceCurrency: 'JPY',
    );
    final map = codec.toMap(item);
    expect(map['plannedDay'], '2027-04-14');
    expect(map['estimatedCostMinorUnits'], 500);
    expect(codec.toMap(codec.fromMap('a', map)), map);
    expect(codec.toMap(spot('b')).containsKey('visited'), isFalse);
    final bad = TripSavedPlace(
      id: 'c',
      tripId: 't1',
      createdByUid: 'anna',
      name: 'x',
      category: TripSavedPlaceCategory.sight,
      visitMinutes: 0,
    );
    expect(codec.problems(bad).single.field, 'visit');
  });

  testWidgets('priority first, visited filter, chips', (tester) async {
    await open(tester, [
      spot('b', priority: 'B'),
      spot('ss', priority: 'SS', visited: true),
      spot('none'),
    ]);
    expect(top(tester, 'Luogo ss'), lessThan(top(tester, 'Luogo b')));
    expect(top(tester, 'Luogo b'), lessThan(top(tester, 'Luogo none')));
    expect(find.byKey(const Key('saved-place-visited-ss')), findsOneWidget);
    await pickFilter(tester, 'saved-place', 'saved-place-filter-visited-todo');
    expect(find.text('Luogo ss'), findsNothing);
    expect(find.text('Luogo b'), findsOneWidget);
  });

  testWidgets('grouped by area and by day with a title per group', (
    tester,
  ) async {
    await open(tester, [
      spot('a', area: 'Gion', day: DateTime(2027, 4, 15)),
      spot('b', area: 'Arashiyama', day: DateTime(2027, 4, 14)),
      spot('c'),
    ]);
    await pickFilter(tester, 'saved-place', 'saved-place-filter-sort-area');
    expect(find.byKey(const Key('saved-place-group-Arashiyama')), findsOne);
    expect(find.byKey(const Key('saved-place-group-Gion')), findsOne);
    expect(find.byKey(const Key('saved-place-group-Senza zona')), findsOne);
    expect(top(tester, 'Luogo b'), lessThan(top(tester, 'Luogo a')));
    await pickFilter(tester, 'saved-place', 'saved-place-filter-sort-day');
    expect(find.byKey(const Key('saved-place-group-Senza giorno')), findsOne);
    expect(top(tester, 'Luogo b'), lessThan(top(tester, 'Luogo a')));
  });

  testWidgets('editor saves the visit block', (tester) async {
    final store = await open(tester, const []);
    await tapKey(tester, 'saved-place-add');
    await tester.enterText(
      find.byKey(const Key('saved-place-name')),
      'Kiyomizu',
    );
    await tapKey(tester, 'saved-place-priority-S');
    await tapKey(tester, 'saved-place-visited');
    await tester.enterText(find.byKey(const Key('saved-place-area')), 'Gion');
    await tester.enterText(find.byKey(const Key('saved-place-minutes')), '75');
    await tester.enterText(find.byKey(const Key('saved-place-cost')), '4');
    await tester.enterText(
      find.byKey(const Key('saved-place-tickets')),
      'https://kiyomizu.jp',
    );
    await tapKey(tester, 'saved-place-save');
    final saved = store.created.single;
    expect(saved.priority, 'S');
    expect(saved.visited, isTrue);
    expect(saved.area, 'Gion');
    expect(saved.visitMinutes, 75);
    expect(saved.entryPriceMinorUnits, 400);
    expect(saved.ticketsUrl, 'https://kiyomizu.jp');
  });
}
