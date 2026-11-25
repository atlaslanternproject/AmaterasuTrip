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
}
