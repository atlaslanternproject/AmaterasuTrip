// Conversione delle note da e verso Firestore (trips/{tripId}/notes) e
// controlli con i limiti di firestore.rules (checklist al massimo 100 voci
// da 300 caratteri).

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'trip_note.dart';

class TripNoteCodec implements TripSectionCodec<TripNote> {
  const TripNoteCodec();

  static const checklistMax = 100;
  static const itemMax = 300;

  @override
  String get collection => 'notes';

  @override
  List<String> get optionalKeys => const [
    'body',
    'pinned',
    'checklist',
    'linkSection',
    'linkId',
    'linkName',
  ];

  @override
  Map<String, dynamic> toMap(TripNote item) => {
    'tripId': item.tripId,
    'createdByUid': item.createdByUid,
    'title': item.title.trim(),
    'visibility': item.isPrivate ? 'private' : 'shared',
    'body': ?TripSectionFields.clean(item.body),
    if (item.pinned) 'pinned': true,
    if (item.checklist.isNotEmpty)
      'checklist': [
        for (final entry in item.checklist)
          {'text': entry.text.trim(), 'done': entry.done},
      ],
    if (item.link case final link?) ...{
      'linkSection': link.section,
      'linkId': link.id,
      'linkName': link.name.trim(),
    },
  };

  @override
  TripNote fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final title = text('title');
    final visibility = data['visibility'];
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (title == null ||
        (visibility != 'shared' && visibility != 'private') ||
        tripId == null ||
        author == null) {
      throw FormatException('Invalid note $id.');
    }
    final raw = data['checklist'];
    final section = text('linkSection');
    final linkId = text('linkId');
    final linkName = text('linkName');
    return TripNote(
      id: id,
      tripId: tripId,
      createdByUid: author,
      title: title,
      body: text('body'),
      isPrivate: visibility == 'private',
      pinned: data['pinned'] == true,
      checklist: [
        if (raw is List)
          for (final entry in raw)
            if (entry is Map && entry['text'] is String)
              TripChecklistItem(
                entry['text'] as String,
                done: entry['done'] == true,
              ),
      ],
      link:
          TripNoteLink.sections.contains(section) &&
              linkId != null &&
              linkName != null
          ? TripNoteLink(section: section!, id: linkId, name: linkName)
          : null,
    );
  }

  @override
  List<TripSectionProblem> problems(TripNote item) {
    final c = TripSectionChecks()
      ..required(item.title, 'title')
      ..maxLength(item.title.trim(), TripSectionFields.nameMax, 'title')
      ..maxLength(item.body, TripSectionFields.notesMax, 'body')
      ..maxLength(item.link?.name, TripSectionFields.nameMax, 'linkName');
    c
      ..check(
        item.checklist.length > checklistMax,
        TripSectionProblemKind.other,
        'checklistSize',
      )
      ..check(
        item.checklist.any((e) => e.text.trim().length > itemMax),
        TripSectionProblemKind.tooLong,
        'checklistItem',
        max: itemMax,
      );
    return c.found;
  }
}
