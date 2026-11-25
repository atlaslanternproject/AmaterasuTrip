// Lettura e scrittura dei soggiorni su Firestore, direttamente dall'app:
// le regole (firestore.rules, stays) controllano permessi e campi.
// Elenco in tempo reale ordinato per data di check-in.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip_stay.dart';
import '../models/trip_stay_codec.dart';
import '../models/trip_stay_validator.dart';
import 'trip_stays_paths.dart';

class TripStaysRepository {
  TripStaysRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  /// Stays of the trip, by check-in day. Documents that cannot be read
  /// (wrong format) are skipped instead of breaking the whole list.
  Stream<List<TripStay>> watch(String tripId) => _firestore
      .collection(TripStaysPaths.stays(tripId))
      .orderBy('checkInDate')
      .snapshots()
      .map((snapshot) {
        final stays = <TripStay>[];
        for (final doc in snapshot.docs) {
          try {
            stays.add(TripStayCodec.fromMap(doc.id, doc.data()));
          } on FormatException {
            continue;
          }
        }
        return stays;
      });

  /// Saves a new stay of the signed-in user and returns its ID.
  Future<String> create(TripStay stay) async {
    final uid = currentUid;
    if (uid == null || uid != stay.createdByUid) {
      throw StateError('The author must be the signed-in user.');
    }
    _validate(stay);
    final ref = _firestore.collection(TripStaysPaths.stays(stay.tripId)).doc();
    await ref.set({
      ...TripStayCodec.toMap(stay),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Replaces the editable fields; author and creation time stay the same.
  /// Fields left empty are removed.
  Future<void> update(TripStay stay) async {
    _validate(stay);
    final data = TripStayCodec.toMap(stay);
    const optional = [
      'checkInTime',
      'checkOutTime',
      'address',
      'city',
      'country',
      'googlePlaceId',
      'latitude',
      'longitude',
      'bookedVia',
      'bookedViaOther',
      'bookingUrl',
      'propertyUrl',
      'confirmationCode',
      'notes',
      'guestUids',
      'expenseId',
      'type',
      'phone',
      'email',
      'estimatedCostMinorUnits',
      'estimatedCostCurrency',
      'freeCancellationUntil',
      'amenities',
      'directions',
      'extras',
    ];
    await _firestore
        .doc(TripStaysPaths.stay(stay.tripId, stay.id))
        .update(
          {
            ...data,
            for (final key in optional)
              if (!data.containsKey(key)) key: FieldValue.delete(),
            'createdByUid': stay.createdByUid,
            'updatedAt': FieldValue.serverTimestamp(),
          }..remove('createdAt'),
        );
  }

  /// Links a shared budget expense to the stay.
  Future<void> linkExpense({
    required String tripId,
    required String stayId,
    required String expenseId,
  }) => _firestore.doc(TripStaysPaths.stay(tripId, stayId)).update({
    'expenseId': expenseId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Allowed by the rules only to the author or the trip owner.
  Future<void> delete({required String tripId, required String stayId}) =>
      _firestore.doc(TripStaysPaths.stay(tripId, stayId)).delete();

  void _validate(TripStay stay) {
    final problems = TripStayValidator.problems(stay);
    if (problems.isNotEmpty) {
      throw ArgumentError('Invalid stay: ${problems.join(', ')}');
    }
  }
}
