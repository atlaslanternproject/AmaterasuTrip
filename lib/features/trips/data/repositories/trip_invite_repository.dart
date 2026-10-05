import 'package:cloud_functions/cloud_functions.dart';

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

  Future<void> acceptTripInvite({
    required String tripId,
    required String token,
    required TripTravellerProfile travellerProfile,
  }) async {
    final callable = _functions.httpsCallable('acceptTripInvite');

    final result = await callable.call<Map<String, dynamic>>({
      'tripId': tripId,
      'token': token,
      'presenceConfirmed': true,
      'travellerProfile': travellerProfile.toMap(),
    });

    final data = result.data;

    if (data['accepted'] != true ||
        data['tripId'] != tripId ||
        data['role'] != 'traveler') {
      throw StateError('Invalid acceptTripInvite response.');
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

class TripTravellerProfile {
  const TripTravellerProfile({
    required this.hasEsimOrInternet,
    required this.hasCheckedBaggage,
    required this.hasCabinBaggage10Kg,
    required this.hasAllergies,
    required this.hasIntolerances,
    required this.hasMedicalAccessibilityInfo,
    this.allergies = '',
    this.intolerances = '',
    this.medicalAccessibilityInfo = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  final bool hasEsimOrInternet;
  final bool hasCheckedBaggage;
  final bool hasCabinBaggage10Kg;

  final bool hasAllergies;
  final bool hasIntolerances;
  final bool hasMedicalAccessibilityInfo;

  final String allergies;
  final String intolerances;
  final String medicalAccessibilityInfo;

  final String emergencyContactName;
  final String emergencyContactPhone;

  Map<String, dynamic> toMap() {
    return {
      'hasEsimOrInternet': hasEsimOrInternet,
      'hasCheckedBaggage': hasCheckedBaggage,
      'hasCabinBaggage10Kg': hasCabinBaggage10Kg,
      'hasAllergies': hasAllergies,
      'hasIntolerances': hasIntolerances,
      'hasMedicalAccessibilityInfo': hasMedicalAccessibilityInfo,
      'allergies': allergies.trim(),
      'intolerances': intolerances.trim(),
      'medicalAccessibilityInfo': medicalAccessibilityInfo.trim(),
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': emergencyContactPhone.trim(),
    };
  }
}
