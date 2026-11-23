// Test automatici del modello delle note: conversione Firestore (privata,
// fissata, checklist) e controlli con i limiti delle regole.
// Casi, ad esempio: "codec round trip keeps private, pinned and checklist", "checklist limits".

import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note_codec.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripNoteCodec();

void main() {
  test('codec round trip keeps private, pinned and checklist', () {
    const note = TripNote(
      tripId: 'trip',
      createdByUid: 'anna',
      title: 'Valigia',
      body: 'Da ricordare',
      isPrivate: true,
      pinned: true,
      checklist: [
        TripChecklistItem('Passaporto', done: true),
        TripChecklistItem('Adattatore'),
      ],
    );
    final map = codec.toMap(note);
    expect(map['visibility'], 'private');
    expect(map['checklist'], [
      {'text': 'Passaporto', 'done': true},
      {'text': 'Adattatore', 'done': false},
    ]);
    final back = codec.fromMap('x', map);
    expect(codec.toMap(back), map);
    expect(back.doneCount, 1);
    expect(
      codec
          .toMap(const TripNote(tripId: 't', createdByUid: 'a', title: 'T'))
          .keys
          .toSet(),
      {'tripId', 'createdByUid', 'title', 'visibility'},
    );
    expect(
      () => codec.fromMap('x', {...map, 'visibility': 'x'}),
      throwsFormatException,
    );
  });

  test('checklist limits', () {
    TripNote withItems(List<TripChecklistItem> items) =>
        TripNote(tripId: 't', createdByUid: 'a', title: 'T', checklist: items);
    expect(codec.problems(withItems([const TripChecklistItem('ok')])), isEmpty);
    expect(
      codec
          .problems(withItems(List.filled(101, const TripChecklistItem('x'))))
          .single
          .field,
      'checklistSize',
    );
    expect(
      codec.problems(withItems([TripChecklistItem('x' * 301)])).single.field,
      'checklistItem',
    );
  });
}
