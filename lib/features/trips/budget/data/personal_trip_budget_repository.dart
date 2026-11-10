import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/personal_trip_budget.dart';

class PersonalTripBudgetRepository {
  PersonalTripBudgetRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestoreOverride = firestore,
       _authOverride = auth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  // Created on first use, so a test double can extend this class.
  late final FirebaseFirestore _firestore =
      _firestoreOverride ?? FirebaseFirestore.instance;
  late final FirebaseAuth _auth = _authOverride ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _document(String tripId) {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError('Authentication required.');
    }

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(tripId)) {
      throw ArgumentError('Invalid trip ID.');
    }

    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('budgetPrivateOwners')
        .doc(uid)
        .collection('settings')
        .doc('personalBudget');
  }

  Stream<PersonalTripBudget?> watch(String tripId) {
    return _document(tripId).snapshots().map(
      (snapshot) => PersonalTripBudget.fromMap(snapshot.data()),
    );
  }

  Future<void> save(String tripId, PersonalTripBudget budget) async {
    if (!budget.isValid) {
      throw ArgumentError('Invalid personal trip budget.');
    }

    await _document(
      tripId,
    ).set({...budget.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> remove(String tripId) async {
    await _document(tripId).delete();
  }
}
