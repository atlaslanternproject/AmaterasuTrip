import 'package:cloud_functions/cloud_functions.dart';

enum TripInviteStatus { missing, active, revoked }

class TripInviteRepository {
  TripInviteRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<TripInviteCredentials> createTripInvite({
    required String tripId,
  }) async {
    final callable = _functions.httpsCallable('createTripInvite');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final data = result.data;
    final inviteId = data['inviteId'];
    final token = data['token'];

    if (inviteId is! String || token is! String) {
      throw StateError('Invalid createTripInvite response.');
    }

    return TripInviteCredentials(
      inviteId: inviteId,
      tripId: tripId,
      token: token,
    );
  }

  Future<bool> revokeTripInvite({required String tripId}) async {
    final callable = _functions.httpsCallable('revokeTripInvite');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final revoked = result.data['revoked'];

    if (revoked is! bool) {
      throw StateError('Invalid revokeTripInvite response.');
    }

    return revoked;
  }

  Future<TripInviteStatus> getTripInviteStatus({required String tripId}) async {
    final callable = _functions.httpsCallable('getTripInviteStatus');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
    });

    final status = result.data['status'];

    return switch (status) {
      'missing' => TripInviteStatus.missing,
      'active' => TripInviteStatus.active,
      'revoked' => TripInviteStatus.revoked,
      _ => throw StateError('Invalid getTripInviteStatus response.'),
    };
  }

  Future<ValidatedTripInvite> validateTripInvite({
    required String tripId,
    required String token,
  }) async {
    final callable = _functions.httpsCallable('validateTripInvite');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'token': token,
    });

    final data = result.data;
    final valid = data['valid'];
    final trip = data['trip'];

    if (valid is! bool || valid != true || trip is! Map) {
      throw StateError('Invalid validateTripInvite response.');
    }

    final normalizedTrip = Map<String, dynamic>.from(trip);

    return ValidatedTripInvite(
      tripId: normalizedTrip['id'] as String? ?? tripId,
      name: normalizedTrip['name'] as String? ?? '',
      destination: normalizedTrip['destination'] as String? ?? '',
      coverUrl: normalizedTrip['coverUrl'] as String?,
      startDate: _dateTimeFromMilliseconds(normalizedTrip['startDate']),
      endDate: _dateTimeFromMilliseconds(normalizedTrip['endDate']),
    );
  }

  /// Accept trip membership without uploading health information.
  Future<void> joinTripInvite({
    required String tripId,
    required String token,
  }) async {
    final callable = _functions.httpsCallable('acceptTripInvite');
    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'token': token,
      'presenceConfirmed': true,
    });

    if (result.data['accepted'] != true ||
        result.data['tripId'] != tripId ||
        result.data['role'] != 'traveler') {
      throw StateError('Invalid invitation acceptance response.');
    }
  }

  Future<int> migrateOwnedTripsMembership() async {
    final callable = _functions.httpsCallable('migrateOwnedTripsMembership');

    final result = await callable.call<Map<String, dynamic>>();

    final migratedTrips = result.data['migratedTrips'];

    if (migratedTrips is! int) {
      throw StateError('Invalid migrateOwnedTripsMembership response.');
    }

    return migratedTrips;
  }

  static DateTime? _dateTimeFromMilliseconds(dynamic value) {
    if (value is! num) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}

class TripInviteCredentials {
  const TripInviteCredentials({
    required this.inviteId,
    required this.tripId,
    required this.token,
  });

  final String inviteId;
  final String tripId;
  final String token;
}

class ValidatedTripInvite {
  const ValidatedTripInvite({
    required this.tripId,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.coverUrl,
  });

  final String tripId;
  final String name;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverUrl;
}
