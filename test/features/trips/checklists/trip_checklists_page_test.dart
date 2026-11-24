// Test automatici della sezione Checklist: creazione da modello (Valigia),
// lista personale, import della vecchia valigia, pagina della lista con
// spunte, aggiunta di voci, filtri, azzera spunte e duplica.
// Casi, ad esempio: "new packing list from the template", "tick, add and reset".

import 'package:amaterasutrip/features/trips/checklists/data/trip_checklist_entries.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/providers/trip_checklists_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/checklists/trip_checklist_detail_page.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/checklists/trip_checklists_page.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/providers/trip_shopping_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

class FakeEntries implements TripChecklistEntries {
  final calls = <String>[];

  @override
  Future<void> save(TripChecklist list, TripChecklistEntry entry) async =>
      calls.add('save ${entry.text} ${entry.category} ${entry.quantity}');

  @override
  Future<void> remove(TripChecklist list, String entryId) async =>
      calls.add('remove $entryId');

  @override
  Future<void> setDone(TripChecklist list, String entryId, bool done) async =>
      calls.add('done $entryId $done');

  @override
  Future<void> resetAll(TripChecklist list) async => calls.add('reset');

  @override
  Future<void> reorder(TripChecklist list, List<String> entryIds) async =>
      calls.add('reorder ${entryIds.join(',')}');

  @override
  Future<void> setCategories(TripChecklist list, List<String> c) async =>
      calls.add('categories ${c.join(',')}');
}

const sample = TripChecklist(
  id: 'l1',
  tripId: 't1',
  createdByUid: 'anna',
  title: 'Valigia',
  categories: ['Vestiti'],
  entries: {
    'a': TripChecklistEntry(
      id: 'a',
      text: 'Calze',
      category: 'Vestiti',
      done: true,
    ),
    'b': TripChecklistEntry(
      id: 'b',
      text: 'Giacca',
      category: 'Vestiti',
      order: 1,
      assigneeUid: 'bruno',
    ),
  },
);

Future<(FakeSectionStore<TripChecklist>, FakeEntries)> open(
  WidgetTester tester,
  Widget page, {
  List<TripChecklist> lists = const [],
  List<TripPackingItem> packing = const [],
}) async {
  bigWindow(tester);
  final store = FakeSectionStore<TripChecklist>(items: lists);
  final entries = FakeEntries();
  await tester.pumpWidget(
    sectionsTestApp(
      page,
      overrides: [
        tripChecklistsStoreProvider.overrideWithValue(store),
        tripChecklistEntriesProvider.overrideWithValue(entries),
        tripPackingStoreProvider.overrideWithValue(
          FakeSectionStore<TripPackingItem>(items: packing),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (store, entries);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('new packing list from the template, personal', (tester) async {
    final (store, _) = await open(
      tester,
      const TripChecklistsPage(tripId: 't1'),
    );
    expect(find.byKey(const Key('checklist-empty')), findsOneWidget);
    await tapKey(tester, 'checklist-add');
    await tapKey(tester, 'checklist-private');
    await tapKey(tester, 'checklist-save');
    final list = store.created.single;
    expect(list.title, 'Valigia');
    expect(list.isPrivate, isTrue);
    expect(list.categories, ['Vestiti', 'Bagno', 'Accessori']);
    expect(list.entries.length, 17);
  });

  testWidgets('card shows the progress; old packing list can be imported', (
    tester,
  ) async {
    final (store, _) = await open(
      tester,
      const TripChecklistsPage(tripId: 't1'),
      lists: [sample],
      packing: const [
        TripPackingItem(
          id: 'p',
          tripId: 't1',
          createdByUid: 'anna',
          name: 'Ombrello',
          quantity: 2,
        ),
      ],
    );
    expect(find.text('1 su 2 · 50%'), findsOneWidget);
    await tapKey(tester, 'checklist-import');
    final imported = store.created.single;
    expect(imported.entries.values.single.text, 'Ombrello');
    expect(imported.entries.values.single.quantity, 2);
  });

  testWidgets('tick, add, filter and reset in the list page', (tester) async {
    final (store, entries) = await open(
      tester,
      const TripChecklistDetailPage(tripId: 't1', listId: 'l1'),
      lists: [sample],
    );
    expect(find.text('Bruno'), findsOneWidget);
    await tapKey(tester, 'checklist-check-b');
    await tester.enterText(
      find.byKey(const Key('checklist-add-Vestiti')),
      'Pigiama',
    );
    await tapKey(tester, 'checklist-add-go-Vestiti');
    expect(entries.calls, ['done b true', 'save Pigiama Vestiti null']);

    await tapKey(tester, 'checklist-entries-filters');
    await tapKey(tester, 'checklist-entries-state-done');
    await tapKey(tester, 'checklist-entries-sheet-done');
    expect(find.text('Calze'), findsOneWidget);
    expect(find.text('Giacca'), findsNothing);

    await tapKey(tester, 'checklist-actions');
    await tester.tap(find.byKey(const Key('checklist-action-reset')));
    await tester.pumpAndSettle();
    expect(entries.calls.last, 'reset');

    await tapKey(tester, 'checklist-actions');
    await tester.tap(find.byKey(const Key('checklist-action-duplicate')));
    await tester.pumpAndSettle();
    final copy = store.created.single;
    expect(copy.title, 'Valigia (copia)');
    expect(copy.doneCount, 0);
  });

  testWidgets('edit an entry in the panel', (tester) async {
    final (_, entries) = await open(
      tester,
      const TripChecklistDetailPage(tripId: 't1', listId: 'l1'),
      lists: [sample],
    );
    await tapKey(tester, 'checklist-entry-a');
    await tester.enterText(
      find.byKey(const Key('checklist-entry-quantity')),
      '4',
    );
    await tapKey(tester, 'checklist-entry-save');
    expect(entries.calls.single, 'save Calze Vestiti 4');
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(
      tester,
      const TripChecklistDetailPage(tripId: 't1', listId: 'l1'),
      lists: [sample],
    );
    tester.view.physicalSize = const Size(360, 2400);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
