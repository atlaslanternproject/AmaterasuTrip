// Modifica delle voci di una checklist una alla volta (items.<id>): due
// persone possono spuntare voci diverse insieme senza sovrascriversi.
// Azzera spunte e riordino cambiano solo i campi necessari; ogni modifica
// è firmata con updatedByUid (Audit Trail).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amaterasutrip/features/trips/sections/data/trip_section_store.dart';
import '../models/trip_checklist.dart';
import '../models/trip_checklist_codec.dart';

abstract interface class TripChecklistEntries {
  Future<void> save(TripChecklist list, TripChecklistEntry entry);
  Future<void> remove(TripChecklist list, String entryId);
  Future<void> setDone(TripChecklist list, String entryId, bool done);
  Future<void> resetAll(TripChecklist list);

  /// New order of the entries of one category (first = 0).
  Future<void> reorder(TripChecklist list, List<String> entryIds);

  /// Category names in their new order.
  Future<void> setCategories(TripChecklist list, List<String> categories);
}

class FirestoreTripChecklistEntries implements TripChecklistEntries {
  FirestoreTripChecklistEntries(this._firestore, [FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _doc(TripChecklist list) =>
      _firestore.doc(
        'trips/${tripSectionCheckedId(list.tripId)}/checklists/'
        '${tripSectionCheckedId(list.id)}',
      );

  Future<void> _update(TripChecklist list, Map<Object, Object?> fields) =>
      _doc(list).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': _auth.currentUser?.uid,
      });

  @override
  Future<void> save(TripChecklist list, TripChecklistEntry entry) {
    if (TripChecklistCodec.entryProblems(entry).isNotEmpty) {
      throw ArgumentError('Invalid checklist entry.');
    }
    return _update(list, {
      FieldPath(['items', entry.id]): TripChecklistCodec.entryMap(entry),
    });
  }

  @override
  Future<void> remove(TripChecklist list, String entryId) => _update(list, {
    FieldPath(['items', entryId]): FieldValue.delete(),
  });

  @override
  Future<void> setDone(TripChecklist list, String entryId, bool done) =>
      _update(list, {
        FieldPath(['items', entryId, 'done']): done,
      });

  @override
  Future<void> resetAll(TripChecklist list) => _update(list, {
    for (final e in list.entries.values)
      if (e.done) FieldPath(['items', e.id, 'done']): false,
  });

  @override
  Future<void> reorder(TripChecklist list, List<String> entryIds) =>
      _update(list, {
        for (final (index, id) in entryIds.indexed)
          FieldPath(['items', id, 'order']): index,
      });

  @override
  Future<void> setCategories(TripChecklist list, List<String> categories) =>
      _update(list, {'categories': List.of(categories)});
}
