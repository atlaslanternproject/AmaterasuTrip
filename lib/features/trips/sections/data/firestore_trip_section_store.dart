// Versione Firestore del TripSectionStore: scrive direttamente dall'app in
// trips/{tripId}/{collection}, con createdAt e updatedAt dell'ora del
// server come chiedono le regole. I documenti illeggibili si saltano.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip_section_item.dart';
import 'trip_section_store.dart';

class FirestoreTripSectionStore<T extends TripSectionItem>
    implements TripSectionStore<T> {
  FirestoreTripSectionStore(this._firestore, this._auth, this.codec);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TripSectionCodec<T> codec;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _items(String tripId) => _firestore
      .collection('trips/${tripSectionCheckedId(tripId)}/${codec.collection}');

  DocumentReference<Map<String, dynamic>> _doc(T item) =>
      _items(item.tripId).doc(tripSectionCheckedId(item.id));

  /// Readable items of [snapshot]; wrong documents are skipped.
  List<T> read(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = <T>[];
    for (final doc in snapshot.docs) {
      try {
        items.add(codec.fromMap(doc.id, doc.data()));
      } on FormatException {
        continue;
      }
    }
    return items;
  }

  @override
  Stream<List<T>> watch(String tripId) => _items(tripId).snapshots().map(read);

  @override
  Future<String> create(T item) async {
    final uid = currentUid;
    if (uid == null || uid != item.createdByUid) {
      throw StateError('The author must be the signed-in user.');
    }
    _validate(item);
    final ref = _items(item.tripId).doc();
    await ref.set({
      ...codec.toMap(item),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<void> update(T item) async {
    _validate(item);
    final data = codec.toMap(item);
    await _doc(item).update(
      {
        ...data,
        for (final key in codec.optionalKeys)
          if (!data.containsKey(key)) key: FieldValue.delete(),
        'createdByUid': item.createdByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }..remove('createdAt'),
    );
  }

  @override
  Future<void> linkExpense(T item, String expenseId) => _doc(
    item,
  ).update({'expenseId': expenseId, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> delete(T item) => _doc(item).delete();

  void _validate(T item) {
    final problems = codec.problems(item);
    if (problems.isNotEmpty) {
      throw ArgumentError('Invalid item: ${problems.join(', ')}');
    }
  }
}
