// Test automatici della pagina Note: modello "Info utili", nota privata con
// checklist, note fissate in alto, voci spuntate dalla card, filtro
// condivise/private e permessi di eliminazione.
// Casi, ad esempio: "useful info template", "tick a checklist item from the card".

import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

TripNote note(
  String id, {
  String createdBy = 'anna',
  bool private = false,
  bool pinned = false,
  List<TripChecklistItem> checklist = const [],
}) => TripNote(
  id: id,
  tripId: 't1',
  createdByUid: createdBy,
  title: 'Nota $id',
  isPrivate: private,
  pinned: pinned,
  checklist: checklist,
);

Future<FakeSectionStore<TripNote>> open(
  WidgetTester tester, {
  List<TripNote> items = const [],
  String uid = 'anna',
  double width = 1000,
}) async {
  bigWindow(tester, width: width);
  final store = FakeSectionStore<TripNote>(uid: uid, items: items);
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

  testWidgets('useful info template, pinned', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'note-add');
    await tapKey(tester, 'note-template-useful');
    await tapKey(tester, 'note-save');
    final saved = store.created.single;
    expect(saved.title, 'Info utili');
    expect(saved.body, contains('Numero di emergenza: 112'));
    expect(saved.pinned, isTrue);
    expect(saved.isPrivate, isFalse);
  });

  testWidgets('private note with a checklist; empty items are skipped', (
    tester,
  ) async {
    final store = await open(tester);
    await tapKey(tester, 'note-add');
    await tester.enterText(find.byKey(const Key('note-title')), 'Valigia');
    await tapKey(tester, 'note-private');
    await tapKey(tester, 'note-item-add');
    await tester.enterText(find.byKey(const Key('note-item-0')), 'Passaporto');
    await tapKey(tester, 'note-item-add');
    await tapKey(tester, 'note-save');
    final saved = store.created.single;
    expect(saved.isPrivate, isTrue);
    expect(saved.checklist.map((i) => i.text), ['Passaporto']);
  });

  testWidgets('pinned first; tick a checklist item from the card', (
    tester,
  ) async {
    final store = await open(
      tester,
      items: [
        note('a'),
        note(
          'z',
          pinned: true,
          checklist: const [TripChecklistItem('Biglietti')],
        ),
      ],
    );
    final first = find
        .byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('note-card-'),
        )
        .first;
    expect(
      (tester.widget(first).key! as ValueKey<String>).value,
      'note-card-z',
    );
    expect(find.text('0 di 1 fatte'), findsOneWidget);
    await tapKey(tester, 'note-check-z-0');
    expect(store.updated.single.checklist.single.done, isTrue);
  });

  testWidgets('filter private notes; the owner cannot delete them', (
    tester,
  ) async {
    await open(
      tester,
      uid: 'anna',
      items: [
        note('s', createdBy: 'bruno'),
        note('p', private: true),
      ],
    );
    await pickFilter(tester, 'note', 'note-filter-kind-private');
    expect(find.byKey(const Key('note-card-p')), findsOneWidget);
    expect(find.byKey(const Key('note-card-s')), findsNothing);
    await pickFilter(tester, 'note', 'note-filter-kind-all');
    // Anna owns the trip: she may delete Bruno's shared note.
    expect(find.byKey(const Key('note-menu-s')), findsOneWidget);
  });

  testWidgets('another member cannot change who reads a note', (tester) async {
    await open(tester, uid: 'bruno', items: [note('a')]);
    await tapKey(tester, 'note-edit-a');
    final privacy = tester.widget<SwitchListTile>(
      find.byKey(const Key('note-private')),
    );
    expect(privacy.onChanged, isNull);
  });

  testWidgets('phone width without overflow', (tester) async {
    await open(tester, width: 360, items: [note('a')]);
    await tapKey(tester, 'note-add');
    expect(tester.takeException(), isNull);
  });
}
