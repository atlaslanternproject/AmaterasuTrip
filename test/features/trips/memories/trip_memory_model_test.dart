// Test automatici del modello dei ricordi: diario (data obbligatoria,
// valutazione 1-5) e album (nome e link obbligatori), conversione Firestore.
// Casi, ad esempio: "diary round trip", "album needs name and link".

import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory_codec.dart';
import 'package:flutter_test/flutter_test.dart';

const codec = TripMemoryCodec();

void main() {
  test('diary round trip', () {
    final day = TripMemory(
      tripId: 't',
      createdByUid: 'anna',
      kind: TripMemoryKind.day,
      date: DateTime(2027, 4, 12),
      text: 'Nara',
      rating: 5,
      moment: 'Il tramonto',
    );
    final map = codec.toMap(day);
    expect(map['kind'], 'day');
    expect(codec.toMap(codec.fromMap('x', map)), map);
    expect(codec.problems(day), isEmpty);
    expect(
      codec
          .problems(
            const TripMemory(
              tripId: 't',
              createdByUid: 'a',
              kind: TripMemoryKind.day,
            ),
          )
          .single
          .field,
      'date',
    );
  });

  test('album needs name and link; rating limits', () {
    const album = TripMemory(
      tripId: 't',
      createdByUid: 'a',
      kind: TripMemoryKind.album,
    );
    expect(codec.problems(album).map((p) => p.field), ['title', 'url']);
    final bad = TripMemory(
      tripId: 't',
      createdByUid: 'a',
      kind: TripMemoryKind.day,
      date: DateTime(2027),
      rating: 6,
    );
    expect(codec.problems(bad).single.field, 'rating');
    expect(() => codec.fromMap('x', {'kind': 'photo'}), throwsFormatException);
  });
}
