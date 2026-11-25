// Una checklist del viaggio (es. Valigia, Documenti): titolo, condivisa o
// personale (la personale la legge solo chi l'ha creata), modello di
// partenza, categorie in ordine e voci (testo, categoria, quantità,
// assegnatario, fatta, ordine), salvate nella lista stessa.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripChecklistEntry {
  const TripChecklistEntry({
    required this.id,
    required this.text,
    required this.category,
    this.quantity,
    this.assigneeUid,
    this.done = false,
    this.order = 0,
    this.usefulLinks = const [],
  });

  /// Key of the entry inside the list (letters, digits, - and _).
  final String id;
  final String text;
  final String category;
  final int? quantity;
  final String? assigneeUid;
  final bool done;
  final int order;

  /// Useful links of the entry (at most 3).
  final List<String> usefulLinks;

  TripChecklistEntry copyWith({
    String? text,
    String? category,
    int? quantity,
    bool clearQuantity = false,
    String? assigneeUid,
    bool clearAssignee = false,
    bool? done,
    int? order,
    List<String>? usefulLinks,
  }) => TripChecklistEntry(
    id: id,
    text: text ?? this.text,
    category: category ?? this.category,
    quantity: clearQuantity ? null : (quantity ?? this.quantity),
    assigneeUid: clearAssignee ? null : (assigneeUid ?? this.assigneeUid),
    done: done ?? this.done,
    order: order ?? this.order,
    usefulLinks: usefulLinks ?? this.usefulLinks,
  );
}

class TripChecklist implements TripSectionItem {
  const TripChecklist({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.title,
    this.isPrivate = false,
    this.template,
    this.categories = const [],
    this.entries = const {},
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String title;

  /// Personal lists are read only by their author (firestore.rules).
  final bool isPrivate;

  /// Template the list started from (e.g. "packing"), for information.
  final String? template;

  /// Category names in the order shown.
  final List<String> categories;
  final Map<String, TripChecklistEntry> entries;

  int get doneCount => entries.values.where((e) => e.done).length;

  /// Entries of [category], in their order.
  List<TripChecklistEntry> entriesOf(String category) =>
      entries.values.where((e) => e.category == category).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// Categories in order, plus any used by entries but not listed.
  List<String> get shownCategories => [
    ...categories,
    ...{
      for (final e in entries.values)
        if (!categories.contains(e.category)) e.category,
    },
  ];

  @override
  String? get expenseId => null;

  @override
  String get displayName => title;
}
