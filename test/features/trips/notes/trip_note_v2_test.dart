// Test automatici delle aggiunte v2 alle note: formattazione di base nella
// card (titolo, elenco, grassetto), modelli Frasi utili e Contatti, barra
// di formattazione, collegamento a un elemento del viaggio e salvataggio.
// Casi, ad esempio: "formatted body in the card", "note linked to a stay".

import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note_codec.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_note_link_targets.dart';
import 'package:amaterasutrip/features/trips/notes/providers/trip_notes_provider.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/notes/trip_notes_page.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sections/support/fake_section_store.dart';

const ryokan = TripNoteLink(section: 'stays', id: 's1', name: 'Ryokan');

Future<FakeSectionStore<TripNote>> open(
  WidgetTester tester, [
  List<TripNote> items = const [],
]) async {
  bigWindow(tester);
  final store = FakeSectionStore<TripNote>(items: items);
  await tester.pumpWidget(
    sectionsTestApp(
      const TripNotesPage(tripId: 't1'),
      overrides: [
        tripNotesStoreProvider.overrideWithValue(store),
        tripNoteLinkTargetsProvider.overrideWith(
          (ref, tripId) async => [ryokan],
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rich text: title, list and bold', () {
    final span = tripSectionRichText(
      '# Check-in\n- Passaporti\nCodice **1234**',
      const TextStyle(),
    );
    expect(span.toPlainText(), 'Check-in\n• Passaporti\nCodice 1234');
    final bold = span.children!.whereType<TextSpan>().where(
      (s) => s.style?.fontWeight == FontWeight.w700,
    );
    expect(bold.map((s) => s.text), ['Check-in', '1234']);
  });

  test('the link is saved with the note', () {
    const codec = TripNoteCodec();
    const note = TripNote(
      tripId: 't1',
      createdByUid: 'anna',
      title: 'Arrivo',
      link: ryokan,
    );
    final map = codec.toMap(note);
    expect(
      (map['linkSection'], map['linkId'], map['linkName']),
      ('stays', 's1', 'Ryokan'),
    );
    expect(codec.fromMap('n1', map).link?.name, 'Ryokan');
  });

  testWidgets('formatted body and link in the card', (tester) async {
    await open(tester, [
      const TripNote(
        id: 'n1',
        tripId: 't1',
        createdByUid: 'anna',
        title: 'Arrivo',
        body: '- Chiavi\n**Codice** 12',
        link: ryokan,
      ),
    ]);
    expect(find.text('Collegata a Ryokan (Hotel e alloggi)'), findsOneWidget);
    expect(find.text('• Chiavi\nCodice 12', findRichText: true), findsOne);
  });

  testWidgets('template, format bar and link are saved', (tester) async {
    final store = await open(tester);
    await tapKey(tester, 'note-add');
    await tapKey(tester, 'note-template-phrases');
    expect(find.text('Frasi utili'), findsWidgets);
    await tester.enterText(find.byKey(const Key('note-body')), 'Chiavi');
    await tapKey(tester, 'note-format-list');
    await tapKey(tester, 'note-link-pick');
    await tapKey(tester, 'note-link-stays-s1');
    await tapKey(tester, 'note-save');
    final saved = store.created.single;
    expect(saved.title, 'Frasi utili');
    expect(saved.body, '- Chiavi');
    expect(saved.link?.id, 's1');
  });
}
