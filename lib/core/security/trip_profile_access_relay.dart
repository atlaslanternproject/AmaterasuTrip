import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_app_check_bootstrap.dart';
import 'first_root_bootstrap_service.dart';
import 'first_root_local_identity.dart';
import 'trip_profile_access_proof.dart';

/// Access-request transport. Never returns private keys or health data.
final class TripProfileAccessRelay {
  TripProfileAccessRelay({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    AmaterasuAppCheckBootstrap.requireReady();
    final result = await _functions
        .httpsCallable(name)
        .call<Map<String, dynamic>>(data);
    return result.data;
  }

  Future<String> request({
    required String tripId,
    required String profileUid,
    required String deviceId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        !user.emailVerified ||
        await FirstRootBootstrapService().inspect() !=
            FirstRootState.activeOnThisDevice) {
      throw StateError('Trusted first device required.');
    }

    final local = await FirstRootLocalIdentityStorage().read(user.uid);

    if (local == null || local.deviceId != deviceId) {
      throw StateError('Local device identity mismatch.');
    }

    final proof = await TripProfileAccessProofSigner().sign(
      uid: user.uid,
      tripId: tripId,
      profileUid: profileUid,
      deviceId: deviceId,
      signingKey: local.signingKey,
    );

    final result = await _call('requestTripProfileAccess', {
      'tripId': tripId,
      'profileUid': profileUid,
      'recipientDeviceId': deviceId,
      'proof': proof,
    });

    final id = result['requestId'];
    if (id is! String || id.isEmpty) {
      throw StateError('Invalid request receipt.');
    }
    return id;
  }

  Future<List<Map<String, dynamic>>> pending(String tripId) async {
    final result = await _call('listMyTripProfileAccessRequests', {
      'tripId': tripId,
    });

    final items = result['requests'];
    if (items is! List) {
      throw StateError('Invalid access request inbox.');
    }
    return [for (final item in items) Map<String, dynamic>.from(item as Map)];
  }

  Future<void> decline({
    required String tripId,
    required String requestId,
  }) async {
    final result = await _call('declineTripProfileAccessRequest', {
      'tripId': tripId,
      'requestId': requestId,
    });

    if (result['declined'] != true) {
      throw StateError('Invalid decline receipt.');
    }
  }
}
