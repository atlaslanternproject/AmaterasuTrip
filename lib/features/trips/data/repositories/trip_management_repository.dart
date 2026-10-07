import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/models/trip.dart';

class TripManagementRepository {
  TripManagementRepository({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<void> setStatus({
    required String tripId,
    required TripStatus status,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable('setTripStatus');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'status': switch (status) {
        TripStatus.active => 'active',
        TripStatus.closed => 'closed',
      },
    });

    final data = result.data;

    if (data['updated'] != true || data['tripId'] != tripId) {
      throw StateError('Invalid setTripStatus response.');
    }
  }

  Future<void> updateCloudArchive({
    required String tripId,
    required TripCloudArchive archive,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable('updateTripCloudArchive');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'archive': archive.toMap(),
    });

    final data = result.data;

    if (data['updated'] != true || data['tripId'] != tripId) {
      throw StateError('Invalid updateTripCloudArchive response.');
    }
  }

  Future<String> duplicateTrip({
    required String tripId,
    required String duplicateName,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable('duplicateTrip');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'duplicateName': duplicateName,
    });

    final data = result.data;

    final newTripId = data['newTripId'];

    if (data['duplicated'] != true ||
        newTripId is! String ||
        newTripId.trim().isEmpty) {
      throw StateError('Invalid duplicateTrip response.');
    }

    return newTripId;
  }

  Future<void> deleteTrip({
    required String tripId,
    required String confirmationName,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable('deleteTrip');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'confirmationName': confirmationName,
    });

    final data = result.data;

    if (data['deleted'] != true || data['tripId'] != tripId) {
      throw StateError('Invalid deleteTrip response.');
    }
  }

  Future<void> _ensureAuthenticated() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    await user.getIdToken();
  }
}
