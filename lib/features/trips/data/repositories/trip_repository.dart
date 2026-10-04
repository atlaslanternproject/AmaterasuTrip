import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Stream<List<Trip>> watchUserTrips({required String uid}) {
    final memberTripsStream = _firestore
        .collection('trips')
        .where('memberUids', arrayContains: uid)
        .snapshots();

    final ownedTripsStream = _firestore
        .collection('trips')
        .where('ownerUid', isEqualTo: uid)
        .snapshots();

    return Stream<List<Trip>>.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? memberSnapshot;
      QuerySnapshot<Map<String, dynamic>>? ownedSnapshot;

      void emitTrips() {
        final tripsById = <String, Trip>{};

        for (final doc in ownedSnapshot?.docs ?? const []) {
          tripsById[doc.id] = Trip.fromFirestore(id: doc.id, data: doc.data());
        }

        for (final doc in memberSnapshot?.docs ?? const []) {
          tripsById[doc.id] = Trip.fromFirestore(id: doc.id, data: doc.data());
        }

        controller.add(tripsById.values.toList());
      }

      final memberSubscription = memberTripsStream.listen((snapshot) {
        memberSnapshot = snapshot;
        emitTrips();
      }, onError: controller.addError);

      final ownedSubscription = ownedTripsStream.listen((snapshot) {
        ownedSnapshot = snapshot;
        emitTrips();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await memberSubscription.cancel();
        await ownedSubscription.cancel();
      };
    });
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

    final ownerMemberRef = tripRef.collection('members').doc(user.uid);
    final batch = _firestore.batch();

    batch.set(tripRef, {
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
      'memberUids': [user.uid],
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(ownerMemberRef, {
      'uid': user.uid,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
      'travellerProfileCompleted': true,
    });

    await batch.commit();

    return tripRef.id;
  }

  Future<void> updateTripInformation({
    required String tripId,
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
    String? description,
  }) async {
    final tripRef = await _ownedTripReference(tripId);

    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Trip name cannot be empty.');
    }

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('Trip end date cannot be before the start date.');
    }

    await tripRef.update({
      'name': trimmedName,
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
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription
      else
        'description': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    // Ensure an auth token is available before invoking the
    // authenticated callable function.
    await user.getIdToken();

    final callable = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('deleteTrip');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final data = result.data;

    if (data['deleted'] != true || data['tripId'] != tripId) {
      throw StateError('Invalid deleteTrip response.');
    }
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
