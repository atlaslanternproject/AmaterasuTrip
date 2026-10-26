import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_app_check_bootstrap.dart';
import 'first_root_bootstrap_service.dart';
import 'first_root_local_identity.dart';
import 'trip_profile_access_proof.dart';
import 'trip_signed_bundle_wire.dart';

/// Signed-package transport. Keys remain client-side; returned bundles
/// are untrusted until verified by VerifiedTripProfileSessions.
final class TripProfileBundleRelay {
  TripProfileBundleRelay({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> args,
  ) async {
    AmaterasuAppCheckBootstrap.requireReady();
    final result = await _functions
        .httpsCallable(name)
        .call<Map<String, dynamic>>(args);
    return result.data;
  }

  Future<Map<String, dynamic>> requesterRoot({
    required String tripId,
    required String requestId,
  }) => _call('getPendingTripAccessRoot', {
    'tripId': tripId,
    'requestId': requestId,
  });

  Future<void> approve({
    required String tripId,
    required String requestId,
    required Map<String, dynamic> bundle,
  }) async {
    final response = await _call('approveInitialTripProfileBundle', {
      'tripId': tripId,
      'requestId': requestId,
      'bundle': bundle,
    });
    if (response['approved'] != true) {
      throw StateError('Signed E2EE package was not accepted.');
    }
  }

  Future<UntrustedSignedTripBundle> read({
    required String tripId,
    required String profileUid,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        !user.emailVerified ||
        await FirstRootBootstrapService().inspect() !=
            FirstRootState.activeOnThisDevice) {
      throw StateError('Trusted first device required.');
    }
    final identity = await FirstRootLocalIdentityStorage().read(user.uid);
    if (identity == null) {
      throw StateError('Local E2EE identity missing.');
    }
    // The original signer correctly rejects self-*requests*. This transport
    // allows proof for a self-*read*, which does not grant new access.
    final nonceKey = await AesGcm.with256bits().newSecretKey();
    final nonce = base64UrlEncode(
      await nonceKey.extractBytes(),
    ).replaceAll('=', '');
    final issuedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    final claim = <String, dynamic>{
      'uid': user.uid,
      'tripId': tripId,
      'profileUid': profileUid,
      'deviceId': identity.deviceId,
      'nonce': nonce,
      'issuedAtMs': issuedAt,
      'expiresAtMs': issuedAt + 120000,
    };
    final signature = await Ed25519().sign(
      TripProfileAccessProofSigner.signingBytes(claim),
      keyPair: identity.signingKey,
    );
    final response = await _call('getApprovedTripProfileBundle', {
      'tripId': tripId,
      'profileUid': profileUid,
      'deviceId': identity.deviceId,
      'proof': {...claim, 'signature': base64Encode(signature.bytes)},
    });
    return TripSignedBundleWire.decodeUntrusted(response['bundle']);
  }
}
