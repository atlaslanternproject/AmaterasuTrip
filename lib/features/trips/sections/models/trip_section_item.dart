// Contratto comune degli elementi delle sezioni del viaggio (trasporti,
// prenotazioni, ristoranti…): identificativo, autore, spesa collegata e
// nome da mostrare, più le regole di conversione e controllo (codec).

/// An item of a trip section, saved in trips/{tripId}/{collection}.
abstract interface class TripSectionItem {
  /// Firestore document ID; empty before the first save.
  String get id;
  String get tripId;
  String get createdByUid;

  /// Linked shared expense of the budget, if any.
  String? get expenseId;

  /// Name used in messages (e.g. the delete confirmation).
  String get displayName;
}

/// How a section saves and checks its items.
abstract interface class TripSectionCodec<T extends TripSectionItem> {
  /// Subcollection of the trip (also in firestore.rules).
  String get collection;

  /// Fields that are removed when left empty in an edit.
  List<String> get optionalKeys;

  /// Fields to save, without createdAt and updatedAt.
  Map<String, dynamic> toMap(T item);

  /// Item from a document; throws FormatException when it is not valid.
  T fromMap(String id, Map<String, dynamic> data);

  /// Problems found (empty = valid), with the limits of firestore.rules.
  List<Object> problems(T item);
}
