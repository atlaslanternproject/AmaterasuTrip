// Un ricordo del viaggio: pagina di diario di un giorno (testo, valutazione
// del giorno da 1 a 5, "il momento del giorno", autore) oppure link a un
// album esterno. Nessuna foto viene caricata su Firebase.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

enum TripMemoryKind { day, album }

class TripMemory implements TripSectionItem {
  const TripMemory({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.kind,
    this.date,
    this.text,
    this.rating,
    this.moment,
    this.title,
    this.url,
    this.usefulLinks = const [],
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final TripMemoryKind kind;

  /// Day of the diary page (diary only).
  final DateTime? date;
  final String? text;

  /// 1 to 5 stars.
  final int? rating;

  /// One sentence: "the moment of the day".
  final String? moment;

  /// Album name and external link (album only).
  final String? title;
  final String? url;

  bool get isAlbum => kind == TripMemoryKind.album;

  @override
  String? get expenseId => null;

  /// Useful links (TripSectionLinks), as in the bucket list.
  final List<String> usefulLinks;

  @override
  String get displayName => title ?? moment ?? text ?? '';
}
