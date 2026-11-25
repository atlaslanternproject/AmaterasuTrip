// Test automatici dei "Link utili" comuni delle sezioni: campo con righe
// da aggiungere e togliere (come nella bucket list), salvataggio, controllo
// dei link non validi e chip nella card. Provati su ristoranti e note.
// Casi, ad esempio: "links are added, saved and shown", "an invalid link is explained".

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/restaurants/trip_restaurants_page.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../restaurants/trip_restaurants_page_test.dart' show FakeVotes;
import 'support/fake_section_store.dart';

Future<FakeSectionStore<TripNote>> openNotes(
  WidgetTester tester, [
  List<TripNote> items = const [],
]) async {
  bigWindow(tester);
  final store = FakeSectionStore<TripNote>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripNotesPage(tripId: 't1'),
      overrides: [tripNotesStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('links: saved only when filled, at most 10, http(s) only', () {
    expect(TripSectionLinks.toMap(const []), isEmpty);
    expect(TripSectionLinks.toMap([' https://a.it ', '']), {
      'usefulLinks': ['https://a.it'],
    });
    expect(TripSectionLinks.invalid(['www.a.it']), isTrue);
    expect(TripSectionLinks.invalid(List.filled(11, 'https://a.it')), isTrue);
    expect(
      TripSectionLinks.read({
        'usefulLinks': ['https://a.it', 5],
      }),
      ['https://a.it'],
    );
  });

  test('checklist entry: up to 3 links, saved with the entry', () {
    const entry = TripChecklistEntry(
      id: 'e1',
      text: 'Passaporto',
      category: 'Documenti',
      usefulLinks: ['https://passaportonline.it'],
    );
    expect(TripChecklistCodec.entryMap(entry)['usefulLinks'], [
      'https://passaportonline.it',
    ]);
    expect(TripChecklistCodec.entryProblems(entry), isEmpty);
    expect(
      TripChecklistCodec.entryProblems(
        entry.copyWith(usefulLinks: List.filled(4, 'https://a.it')),
      ).single.field,
      'usefulLinks',
    );
  });

  testWidgets('note: links are added, removed, saved and shown', (
    tester,
  ) async {
    final store = await openNotes(tester);
    await tapKey(tester, 'note-add');
    await tester.enterText(find.byKey(const Key('note-title')), 'Musei');
    await tester.tap(find.text('Link utili'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-link-0')),
      'https://ghibli-museum.jp',
    );
    await tapKey(tester, 'note-link-add');
    await tester.enterText(
      find.byKey(const Key('note-link-1')),
      'https://x.it',
    );
    await tapKey(tester, 'note-link-add');
    await tapKey(tester, 'note-link-remove-2');
    await tapKey(tester, 'note-save');
    expect(store.created.single.usefulLinks, [
      'https://ghibli-museum.jp',
      'https://x.it',
    ]);
  });

  testWidgets('an invalid link is explained and nothing is saved', (
    tester,
  ) async {
    final store = await openNotes(tester);
    await tapKey(tester, 'note-add');
    await tester.enterText(find.byKey(const Key('note-title')), 'Musei');
    await tester.tap(find.text('Link utili'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-link-0')), 'ghibli');
    await tapKey(tester, 'note-save');
    expect(store.created, isEmpty);
  });

  testWidgets('restaurant card shows the site of each useful link', (
    tester,
  ) async {
    bigWindow(tester);
    await tester.pumpWidget(
      sectionsTestApp(
        const TripRestaurantsPage(tripId: 't1'),
        overrides: [
          tripRestaurantsStoreProvider.overrideWithValue(
            FakeSectionStore<TripRestaurant>(
              items: const [
                TripRestaurant(
                  id: 'r1',
                  tripId: 't1',
                  createdByUid: 'anna',
                  name: 'Afuri',
                  usefulLinks: ['https://tabelog.com/afuri'],
                ),
              ],
            ),
          ),
          tripRestaurantVotesProvider.overrideWithValue(FakeVotes()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('tabelog.com'), findsOneWidget);
  });
}
