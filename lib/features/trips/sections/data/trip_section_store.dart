// Lettura e scrittura degli elementi di una sezione del viaggio: elenco in
// tempo reale, creazione, modifica (i campi vuoti si tolgono), spesa
// collegata ed eliminazione. Le regole in firestore.rules decidono chi può.

import '../models/trip_section_item.dart';

abstract interface class TripSectionStore<T extends TripSectionItem> {
  String? get currentUid;

  Stream<List<T>> watch(String tripId);

  /// Saves a new item of the signed-in user and returns its ID.
  Future<String> create(T item);

  /// Replaces the editable fields; author and creation time stay the same.
  Future<void> update(T item);

  Future<void> linkExpense(T item, String expenseId);

  /// Allowed by the rules only to the author or the trip owner.
  Future<void> delete(T item);
}

/// Document IDs cannot be empty, contain "/" or have spaces at the edges.
String tripSectionCheckedId(String value) {
  if (value.trim().isEmpty || value != value.trim() || value.contains('/')) {
    throw ArgumentError.value(value, 'id', 'Invalid document ID');
  }
  return value;
}
