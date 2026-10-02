import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';

class TripRepository {
  TripRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Trip?> watchTrip(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map((doc) {
      final data = doc.data();

      if (!doc.exists || data == null) {
        return null;
      }

      return Trip.fromFirestore(id: doc.id, data: data);
    });
  }

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
    required String destinationPlaceId,
    required String destinationDisplayName,
    required String destinationFormattedAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    String? destinationCountry,
    String? destinationCountryCode,
    String? destinationAdministrativeArea,
    String? destinationLocality,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
    TripCloudArchive? cloudArchive,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final tripRef = _firestore.collection('trips').doc();

    await tripRef.set({
      'name': name.trim(),
      'destination': destination,
      'destinationData': {
        'placeId': destinationPlaceId,
        'displayName': destinationDisplayName,
        'formattedAddress': destinationFormattedAddress,
        'latitude': destinationLatitude,
        'longitude': destinationLongitude,
        'country': ?destinationCountry,
        'countryCode': ?destinationCountryCode,
        'administrativeArea': ?destinationAdministrativeArea,
        'locality': ?destinationLocality,
      },
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'currency': currency,
      if (cloudArchive != null) 'cloudArchive': cloudArchive.toMap(),
      'ownerUid': user.uid,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return tripRef.id;
  }

  Future<void> updateTripCover({
    required String tripId,
    required String coverUrl,
    required String coverPath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final tripRef = _firestore.collection('trips').doc(tripId);
    final snapshot = await tripRef.get();

    if (!snapshot.exists) {
      throw StateError('Trip not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Trip not found.');
    }

    if (data['ownerUid'] != user.uid) {
      throw StateError('Current user cannot manage this trip.');
    }

    await tripRef.update({
      'coverUrl': coverUrl,
      'coverPath': coverPath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeTripCover({required String tripId}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final tripRef = _firestore.collection('trips').doc(tripId);
    final snapshot = await tripRef.get();

    if (!snapshot.exists) {
      throw StateError('Trip not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Trip not found.');
    }

    if (data['ownerUid'] != user.uid) {
      throw StateError('Current user cannot manage this trip.');
    }

    await tripRef.update({
      'coverUrl': FieldValue.delete(),
      'coverPath': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCloudArchive({
    required String tripId,
    required TripCloudArchive cloudArchive,
  }) async {
    final tripRef = await _ownedTripReference(tripId);

    await tripRef.update({
      'cloudArchive': cloudArchive.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCloudArchive({required String tripId}) async {
    final tripRef = await _ownedTripReference(tripId);

    await tripRef.update({
      'cloudArchive': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTrip({required String tripId}) async {
    final tripRef = await _ownedTripReference(tripId);
    await tripRef.delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> _ownedTripReference(
    String tripId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final tripRef = _firestore.collection('trips').doc(tripId);
    final snapshot = await tripRef.get();

    if (!snapshot.exists) {
      throw StateError('Trip not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Trip not found.');
    }

    if (data['ownerUid'] != user.uid) {
      throw StateError('Current user cannot manage this trip.');
    }

    return tripRef;
  }
}
