// Una nota del viaggio: titolo, testo, condivisa o privata (la privata la
// legge solo chi l'ha scritta), fissata in alto, checklist con voci da
// spuntare, collegamento facoltativo a un elemento del viaggio (alloggio,
// trasporto, prenotazione, ristorante o luogo). I modelli (Info utili,
// Frasi utili, Contatti) sono note già scritte.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripChecklistItem {
  const TripChecklistItem(this.text, {this.done = false});

  final String text;
  final bool done;

  TripChecklistItem toggled() => TripChecklistItem(text, done: !done);
}

/// Element of another section the note talks about (name kept as shown
/// when it was linked).
class TripNoteLink {
  const TripNoteLink({
    required this.section,
    required this.id,
    required this.name,
  });

  static const sections = [
    'stays',
    'transports',
    'reservations',
    'restaurants',
    'savedPlaces',
  ];

  final String section;
  final String id;
  final String name;
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
    this.link,
    this.usefulLinks = const [],
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
  final TripNoteLink? link;

  int get doneCount => checklist.where((item) => item.done).length;

  @override
  String? get expenseId => null;

  /// Useful links (TripSectionLinks), as in the bucket list.
  final List<String> usefulLinks;

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
    link: link,
    usefulLinks: usefulLinks,
  );
}
