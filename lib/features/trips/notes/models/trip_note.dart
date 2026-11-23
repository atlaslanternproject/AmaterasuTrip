// Una nota del viaggio: titolo, testo, condivisa o privata (la privata la
// legge solo chi l'ha scritta), fissata in alto, checklist con voci da
// spuntare. Le "Info utili" sono una nota creata da un modello.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripChecklistItem {
  const TripChecklistItem(this.text, {this.done = false});

  final String text;
  final bool done;

  TripChecklistItem toggled() => TripChecklistItem(text, done: !done);
}

class TripNote implements TripSectionItem {
  const TripNote({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.title,
    this.body,
    this.isPrivate = false,
    this.pinned = false,
    this.checklist = const [],
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String title;
  final String? body;

  /// Private notes are read only by their author (firestore.rules).
  final bool isPrivate;
  final bool pinned;
  final List<TripChecklistItem> checklist;

  int get doneCount => checklist.where((item) => item.done).length;

  @override
  String? get expenseId => null;

  @override
  String get displayName => title;

  TripNote withChecklist(List<TripChecklistItem> items) => TripNote(
    id: id,
    tripId: tripId,
    createdByUid: createdByUid,
    title: title,
    body: body,
    isPrivate: isPrivate,
    pinned: pinned,
    checklist: items,
  );
}
