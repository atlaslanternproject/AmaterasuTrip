// Conversione dei ricordi da e verso Firestore (trips/{tripId}/memories) e
// controlli con i limiti di firestore.rules: il diario ha la data, l'album
// ha nome e link.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_dates.dart';
import 'trip_memory.dart';

class TripMemoryCodec implements TripSectionCodec<TripMemory> {
  const TripMemoryCodec();

  static const momentMax = 300;

  @override
  String get collection => 'memories';

  @override
  List<String> get optionalKeys => const [
    'date',
    'text',
    'rating',
    'moment',
    'title',
    'url',
  ];

  @override
  Map<String, dynamic> toMap(TripMemory item) {
    String? text(String? value) => TripSectionFields.clean(value);
    final date = item.date;
    return {
      'tripId': item.tripId,
      'createdByUid': item.createdByUid,
      'kind': item.kind.name,
      if (date != null) 'date': TripStayDates.format(date),
      'text': ?text(item.text),
      'rating': ?item.rating,
      'moment': ?text(item.moment),
      'title': ?text(item.title),
      'url': ?text(item.url),
    };
  }

  @override
  TripMemory fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final kind = switch (data['kind']) {
      'day' => TripMemoryKind.day,
      'album' => TripMemoryKind.album,
      _ => null,
    };
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (kind == null || tripId == null || author == null) {
      throw FormatException('Invalid memory $id.');
    }
    final rating = data['rating'];
    return TripMemory(
      id: id,
      tripId: tripId,
      createdByUid: author,
      kind: kind,
      date: TripStayDates.parse(data['date']),
      text: text('text'),
      rating: rating is int ? rating : null,
      moment: text('moment'),
      title: text('title'),
      url: text('url'),
    );
  }

  @override
  List<TripSectionProblem> problems(TripMemory item) {
    final rating = item.rating;
    final c = TripSectionChecks()
      ..maxLength(item.text, TripSectionFields.notesMax, 'text')
      ..maxLength(item.moment, momentMax, 'moment')
      ..maxLength(item.title, TripSectionFields.nameMax, 'title');
    if (item.isAlbum) {
      c
        ..required(item.title, 'title')
        ..required(item.url, 'url');
    }
    c
      ..check(
        !item.isAlbum && item.date == null,
        TripSectionProblemKind.other,
        'date',
      )
      ..check(
        rating != null && (rating < 1 || rating > 5),
        TripSectionProblemKind.other,
        'rating',
      )
      ..check(
        TripSectionFields.badLink(item.url),
        TripSectionProblemKind.link,
        'url',
      );
    return c.found;
  }
}
