// Test automatici del modello delle checklist: conversione Firestore (voci
// nella lista), limiti delle regole e modelli pronti.
// Casi, ad esempio: "codec round trip keeps entries", "packing template has three categories".

import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_templates.dart';
import 'package:amaterasutrip/l10n/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripChecklistCodec();

TripChecklist list({Map<String, TripChecklistEntry> entries = const {}}) =>
    TripChecklist(
      tripId: 't',
      createdByUid: 'anna',
      title: 'Valigia',
      isPrivate: true,
      categories: const ['Vestiti'],
      entries: entries,
    );

void main() {
  test('codec round trip keeps entries', () {
    final saved = list(
      entries: const {
        'e1': TripChecklistEntry(
          id: 'e1',
          text: 'Calze',
          category: 'Vestiti',
          quantity: 5,
          assigneeUid: 'bruno',
          done: true,
          order: 2,
        ),
      },
    );
    final map = codec.toMap(saved);
    expect(map['visibility'], 'private');
    expect((map['items'] as Map)['e1'], {
      'text': 'Calze',
      'category': 'Vestiti',
      'done': true,
      'order': 2,
      'quantity': 5,
      'assigneeUid': 'bruno',
    });
    final back = codec.fromMap('x', map);
    expect(codec.toMap(back), map);
    expect(back.doneCount, 1);
    expect(back.entriesOf('Vestiti').single.text, 'Calze');
  });

  test('limits of the rules', () {
    TripChecklistEntry entry(String id, {String text = 'x', int? quantity}) =>
        TripChecklistEntry(
          id: id,
          text: text,
          category: 'C',
          quantity: quantity,
        );
    expect(codec.problems(list()), isEmpty);
    expect(
      TripChecklistCodec.entryProblems(entry('ok', quantity: 999)),
      isEmpty,
    );
    expect(TripChecklistCodec.entryProblems(entry('a b')).single.field, 'id');
    expect(
      TripChecklistCodec.entryProblems(entry('q', quantity: 0)).single.field,
      'quantity',
    );
    expect(
      TripChecklistCodec.entryProblems(entry('t', text: ' ')).single.field,
      'text',
    );
    final many = {for (var i = 0; i < 301; i++) 'e$i': entry('e$i')};
    expect(codec.problems(list(entries: many)).single.field, 'entries');
  });

  test('packing template has three categories and starts unchecked', () {
    final templates = TripChecklistTemplates.all(AppLocalizationsIt());
    expect(templates.map((t) => t.code), [
      'packing',
      'documents',
      'beforeTrip',
      'leavingHome',
      'health',
      'electronics',
      'empty',
    ]);
    final packing = templates.first.build(
      tripId: 't',
      authorUid: 'anna',
      title: 'Valigia',
      isPrivate: false,
    );
    expect(packing.categories, ['Vestiti', 'Bagno', 'Accessori']);
    expect(packing.entries.length, 17);
    expect(packing.doneCount, 0);
    expect(codec.problems(packing), isEmpty);
    expect(packing.entriesOf('Vestiti').first.text, 'Magliette');
  });
}
