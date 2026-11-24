// Test automatici della pagina Ricordi: pagina di diario con valutazione e
// momento del giorno, album con link obbligatorio, autore, filtro e viste.
// Casi, ad esempio: "diary page with stars", "album needs a link".

import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/providers/trip_memories_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/memories/trip_memories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

Future<FakeSectionStore<TripMemory>> open(
  WidgetTester tester, {
  List<TripMemory> items = const [],
  double width = 1000,
}) async {
  bigWindow(tester, width: width);
  final store = FakeSectionStore<TripMemory>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      TripMemoriesPage(tripId: 't1', today: DateTime(2027, 4, 12)),
      overrides: [tripMemoriesStoreProvider.overrideWithValue(store)],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('diary page with stars and moment', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'memory-add');
    await tapKey(tester, 'memory-rating-4');
    await tester.enterText(
      find.byKey(const Key('memory-moment')),
      'Il tramonto',
    );
    await tester.enterText(find.byKey(const Key('memory-text')), 'Nara');
    await tapKey(tester, 'memory-save');
    final saved = store.created.single;
    expect(saved.kind, TripMemoryKind.day);
    expect(saved.date, DateTime(2027, 4, 12));
    expect(saved.rating, 4);
    expect(saved.moment, 'Il tramonto');
  });

  testWidgets('album needs a link', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'memory-add');
    await tapKey(tester, 'memory-kind-album');
    await tester.enterText(find.byKey(const Key('memory-title')), 'Kyoto');
    await tapKey(tester, 'memory-save');
    expect(find.text('Compila il campo «Link all\'album».'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('memory-url')),
      'https://photos.app.goo.gl/abc',
    );
    await tapKey(tester, 'memory-save');
    expect(store.created.single.url, 'https://photos.app.goo.gl/abc');
  });

  testWidgets('cards with author and stars; filter albums', (tester) async {
    await open(
      tester,
      items: [
        TripMemory(
          id: 'd',
          tripId: 't1',
          createdByUid: 'bruno',
          kind: TripMemoryKind.day,
          date: DateTime(2027, 4, 11),
          rating: 3,
        ),
        const TripMemory(
          id: 'a',
          tripId: 't1',
          createdByUid: 'anna',
          kind: TripMemoryKind.album,
          title: 'Foto',
          url: 'https://photos.app.goo.gl/x',
        ),
      ],
    );
    expect(find.text('Scritto da Bruno'), findsOneWidget);
    expect(find.text('★★★☆☆'), findsOneWidget);
    await tapKey(tester, 'memory-filter-kind-album');
    expect(find.byKey(const Key('memory-card-a')), findsOneWidget);
    expect(find.byKey(const Key('memory-card-d')), findsNothing);
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360);
    await tapKey(tester, 'memory-add');
    expect(tester.takeException(), isNull);
  });
}
