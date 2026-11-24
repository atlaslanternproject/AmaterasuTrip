// Test automatici della pagina Luoghi salvati: luogo da link di Google Maps
// incollato, luogo cercato su Google, chi l'ha aggiunto, filtro per
// categoria, viste ed eliminazione.
// Casi, ad esempio: "a pasted Maps link fills name and position", "filter by category".

import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/saved_places/trip_saved_places_page.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';
import '../stays/support/fake_trip_stays.dart' show FakePlaceInfo;
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';

TripSavedPlace place(
  String id, {
  String createdBy = 'anna',
  TripSavedPlaceCategory category = TripSavedPlaceCategory.sight,
}) => TripSavedPlace(
  id: id,
  tripId: 't1',
  createdByUid: createdBy,
  name: 'Luogo $id',
  category: category,
  mapsUrl: 'https://maps.app.goo.gl/$id',
);

Future<FakeSectionStore<TripSavedPlace>> open(
  WidgetTester tester, {
  List<TripSavedPlace> items = const [],
  String uid = 'anna',
  double width = 1000,
  FakePlaceInfo? placeInfo,
}) async {
  bigWindow(tester, width: width);
  final store = FakeSectionStore<TripSavedPlace>(uid: uid, items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripSavedPlacesPage(tripId: 't1'),
      placeInfo: placeInfo,
      overrides: [tripSavedPlacesStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a pasted Maps link fills name and position', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'saved-place-add');
    await tester.enterText(
      find.byKey(const Key('saved-place-link')),
      'https://www.google.com/maps/place/Kinkaku-ji/@35.0394,135.7292,17z',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'saved-place-category-nature');
    await tapKey(tester, 'saved-place-save');
    final item = store.created.single;
    expect(item.name, 'Kinkaku-ji');
    expect(item.place.latitude, 35.0394);
    expect(item.category, TripSavedPlaceCategory.nature);
    expect(item.mapsUrl, startsWith('https://www.google.com/maps/place/'));
  });

  testWidgets('Google search; a name is required', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'saved-place-add');
    await tapKey(tester, 'saved-place-save');
    expect(find.text('Compila il campo «Nome del luogo».'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('saved-place-search')),
      'granvia',
    );
    await tapKey(tester, 'saved-place-search-go');
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'saved-place-save');
    expect(store.created.single.place.placeId, 'ChIJ-kyoto');
  });

  testWidgets('who added it, filter by category, Elenco view', (tester) async {
    await open(
      tester,
      items: [
        place('a', createdBy: 'bruno'),
        place('b', category: TripSavedPlaceCategory.food),
      ],
    );
    expect(find.text('Aggiunto da Bruno'), findsOneWidget);
    await pickFilter(tester, 'saved-place', 'saved-place-filter-kind-food');
    expect(find.byKey(const Key('saved-place-card-b')), findsOneWidget);
    expect(find.byKey(const Key('saved-place-card-a')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('saved-place-view')),
        matching: find.text('Elenco'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved-place-compact-b')), findsOneWidget);
    expect(find.byKey(const Key('saved-place-quick-map-b')), findsOneWidget);
  });

  testWidgets('the owner deletes a place added by someone else', (
    tester,
  ) async {
    final store = await open(tester, items: [place('a', createdBy: 'bruno')]);
    await tapKey(tester, 'saved-place-menu-a');
    await tester.tap(find.byKey(const Key('saved-place-delete-a')));
    await tester.pumpAndSettle();
    // Two steps: destructive actions are confirmed twice.
    await tapKey(tester, 'saved-place-delete-ok');
    expect(
      find.text('Sei sicuro? Questa azione non si può annullare.'),
      findsOneWidget,
    );
    await tapKey(tester, 'saved-place-delete-ok');
    expect(store.deleted.single.id, 'a');
  });

  testWidgets('Google place fills phone and website; Contatta works', (
    tester,
  ) async {
    final store = await open(
      tester,
      placeInfo: FakePlaceInfo(
        contactsResult: const AmaterasuPlaceContacts(
          phone: '+81 75 641',
          website: 'https://inari.jp',
        ),
      ),
    );
    await tapKey(tester, 'saved-place-add');
    await tester.enterText(
      find.byKey(const Key('saved-place-search')),
      'granvia',
    );
    await tapKey(tester, 'saved-place-search-go');
    await tester.tap(find.text('Hotel Granvia'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'saved-place-save');
    expect(store.created.single.phone, '+81 75 641');
    expect(store.created.single.website, 'https://inari.jp');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, items: [place('a')]);
    await tapKey(tester, 'saved-place-add');
    expect(tester.takeException(), isNull);
  });
}
