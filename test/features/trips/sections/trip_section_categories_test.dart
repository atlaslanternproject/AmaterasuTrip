// Test automatici delle categorie personalizzate comuni (Extra D): pulizia
// ed etichette, limiti, editor con categoria nuova o già usata nel viaggio
// (selezione multipla fino a 5), salvataggio e chip nella card. Provati su
// luoghi salvati e note.
// Casi, ad esempio: "new and known categories are saved", "at most 5".

import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/saved_places/trip_saved_places_page.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_categories.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/bookings/trip_bookings_page.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_section_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('labels: cleaned, ids, limits', () {
    expect(
      TripSectionCategories.clean('  Da  non | perdere '),
      'Da non perdere',
    );
    expect(TripSectionCategories.idOf('Città d\'arte!'), 'citt-d-arte');
    expect(TripSectionCategories.toMap(const []), isEmpty);
    expect(TripSectionCategories.invalid(List.filled(6, 'x')), isTrue);
    expect(TripSectionCategories.invalid(['x' * 61]), isTrue);
    expect(TripSectionCategories.invalid(['Romantico']), isFalse);
  });

  testWidgets('new and known categories are saved, shown in the card', (
    tester,
  ) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripSavedPlace>();
    final categories = FakeCategoriesStore(const ['Da non perdere']);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripSavedPlacesPage(tripId: 't1'),
        categories: categories,
        overrides: [tripSavedPlacesStoreProvider.overrideWithValue(store)],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'saved-place-add');
    await tester.enterText(find.byKey(const Key('saved-place-name')), 'Inari');
    await tester.tap(find.text('Categorie personalizzate'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'saved-place-category-known-Da non perdere');
    await tester.enterText(
      find.byKey(const Key('saved-place-category-text')),
      'Al tramonto',
    );
    await tapKey(tester, 'saved-place-category-add');
    await tapKey(tester, 'saved-place-save');
    final saved = store.created.single;
    expect(saved.customCategories, ['Da non perdere', 'Al tramonto']);
    expect(categories.saved, contains('Al tramonto'));
  });

  testWidgets('a card shows the custom categories', (tester) async {
    bigWindow(tester);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripSavedPlacesPage(tripId: 't1'),
        overrides: [
          tripSavedPlacesStoreProvider.overrideWithValue(
            FakeSectionStore<TripSavedPlace>(
              items: const [
                TripSavedPlace(
                  id: 'p1',
                  tripId: 't1',
                  createdByUid: 'anna',
                  name: 'Gion',
                  category: TripSavedPlaceCategory.sight,
                  customCategories: ['Romantico'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Romantico'), findsOneWidget);
  });

  testWidgets('at most 5 categories', (tester) async {
    bigWindow(tester);
    final store = FakeSectionStore<TripNote>();
    await tester.pumpWidget(
      sectionsTestApp(
        const TripNotesPage(tripId: 't1'),
        overrides: [tripNotesStoreProvider.overrideWithValue(store)],
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'note-add');
    await tester.enterText(find.byKey(const Key('note-title')), 'Idee');
    await tester.tap(find.text('Categorie personalizzate'));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 5; i++) {
      await tester.enterText(
        find.byKey(const Key('note-category-text')),
        'C$i',
      );
      await tapKey(tester, 'note-category-add');
    }
    expect(find.text('Al massimo 5 categorie'), findsOneWidget);
    await tapKey(tester, 'note-save');
    expect(store.created.single.customCategories, hasLength(5));
  });

  test('shared filter: custom category, cleared with the others', () {
    const filter = TripSectionFilter(custom: 'Romantico');
    final shown = filter.apply(
      const [
        ['Romantico'],
        ['Altro'],
        <String>[],
      ],
      today: DateTime(2027),
      dayOf: (_) => null,
      categoriesOf: (labels) => labels,
    );
    expect(shown, [
      ['Romantico'],
    ]);
    expect(filter.cleared().custom, 'all');
  });

  TripSavedPlace place(String id, List<String> labels) => TripSavedPlace(
    id: id,
    tripId: 't1',
    createdByUid: 'anna',
    name: 'Luogo $id',
    category: TripSavedPlaceCategory.sight,
    customCategories: labels,
  );

  testWidgets('saved places: filter by custom category', (tester) async {
    bigWindow(tester);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripSavedPlacesPage(tripId: 't1'),
        overrides: [
          tripSavedPlacesStoreProvider.overrideWithValue(
            FakeSectionStore<TripSavedPlace>(
              items: [
                place('a', const ['Romantico']),
                place('b', const []),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await pickFilter(
      tester,
      'saved-place',
      'saved-place-filter-custom-category-Romantico',
    );
    expect(find.text('Luogo a'), findsOneWidget);
    expect(find.text('Luogo b'), findsNothing);
  });

  testWidgets('bookings: the filter appears only with categories', (
    tester,
  ) async {
    bigWindow(tester);
    await tester.pumpWidget(
      sectionsTestApp(
        TripBookingsPage(tripId: 't1', today: DateTime(2027, 4, 1)),
        overrides: [
          tripReservationsStoreProvider.overrideWithValue(
            FakeSectionStore<TripReservation>(
              items: const [
                TripReservation(
                  id: 'r1',
                  tripId: 't1',
                  createdByUid: 'anna',
                  name: 'Museo',
                  category: TripReservationCategory.entry,
                  customCategories: ['Con i bambini'],
                ),
                TripReservation(
                  id: 'r2',
                  tripId: 't1',
                  createdByUid: 'anna',
                  name: 'Tour',
                  category: TripReservationCategory.tour,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await pickFilter(
      tester,
      'reservation',
      'reservation-filter-custom-category-Con i bambini',
    );
    expect(find.text('Museo'), findsOneWidget);
    expect(find.text('Tour'), findsNothing);
  });
}
