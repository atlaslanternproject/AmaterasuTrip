import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';

class TripRepository {
  TripRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Trip>> watchUserTrips() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('trips')
        .where('ownerUid', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Trip.fromFirestore(id: doc.id, data: doc.data()))
              .toList(),
        );
  }

  Future<String> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final tripRef = _firestore.collection('trips').doc();

    await tripRef.set({
      'name': name.trim(),
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'currency': currency,
      'ownerUid': user.uid,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return tripRef.id;
  }
}
