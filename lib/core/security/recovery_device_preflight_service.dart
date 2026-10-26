import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';

import 'device_enrollment_request.dart';
import 'first_root_recovery_record.dart';
import 'recovery_device_approval_proof.dart';
import 'recovery_device_registration_confirmation.dart';

import 'first_root_bootstrap_service.dart';
import 'first_root_recovery_read_service.dart';
import 'pending_recovery_device_identity.dart';
import 'pending_recovery_device_storage.dart';
import 'recovery_device_readiness_gate.dart';

/// Secure client-side preflight.
///
/// Never uploads private keys or recovery codes.
/// Never approves a device or grants access to encrypted data.
final class RecoveryDevicePreflightService {
  final _bootstrap = FirstRootBootstrapService();
  final _pending = PendingRecoveryDeviceStorage();
  final _gate = const RecoveryDeviceReadinessGate();

  /// Submit a signed recovery proof to the enrollment service.
  ///
  /// The recovery code and private keys remain on this device.
  /// Server registration does NOT unlock encrypted trip data.
  Future<void> enrolRecoveredDevice(String recoveryCode) async {
    final user = _verifiedUser();
    final uid = user.uid;

    if (recoveryCode.length < 16 || recoveryCode.length > 4096) {
      throw const FormatException('Invalid recovery code.');
    }

    if (!_gate.canPrepare(await inspect())) {
      throw StateError('Device recovery is not permitted.');
    }

    final token = await user.getIdTokenResult(true);
    final authTime = token.authTime;

    if (authTime == null ||
        DateTime.now().toUtc().difference(authTime.toUtc()).abs() >
            const Duration(minutes: 5)) {
      throw StateError('Recent sign-in required.');
    }

    final pending = await _pending.read(uid);

    if (pending == null) {
      throw StateError('Prepare this device first.');
    }

    // Read the original root from the server, never offline cache.
    final snapshot = await FirebaseFirestore.instance
        .collection('e2eeRoots')
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    final raw = snapshot.data();

    if (raw == null) {
      throw StateError('Registered root unavailable.');
    }

    final record = FirstRootRecoveryRecord.fromServer(uid: uid, data: raw);

    // Client-side recovery. The secret is NOT transmitted.
    final recovered = await record.recover(recoveryCode);

    if (recovered.uid != uid) {
      throw StateError('Recovery account mismatch.');
    }

    final newExchange = await X25519().newKeyPairFromSeed(
      pending.exchangePrivate,
    );

    final newSigning = await Ed25519().newKeyPairFromSeed(
      pending.signingPrivate,
    );

    final xPublic = await newExchange.extractPublicKey();
    final edPublic = await newSigning.extractPublicKey();

    if (!_equal(xPublic.bytes, pending.exchangePublic) ||
        !_equal(edPublic.bytes, pending.signingPublic)) {
      throw StateError('Pending device keys changed.');
    }

    final request = await DeviceEnrollmentRequest.create(
      userUid: uid,
      newDeviceId: pending.deviceId,
      x25519PublicKey: pending.exchangePublic,
      ed25519PublicKey: pending.signingPublic,
      nowUtc: DateTime.now().toUtc(),
    );

    final proof = await RecoveryDeviceApprovalProofService().create(
      recoveredRoot: recovered,
      registeredRoot: record.signed,
      recoveredFingerprint: record.fingerprint,
      request: request,
      newExchangeKey: newExchange,
      newSigningKey: newSigning,
      nowUtc: DateTime.now().toUtc(),
    );

    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Account changed.');
    }

    final persisted = await _pending.read(uid);

    if (persisted == null ||
        persisted.deviceId != pending.deviceId ||
        !_equal(persisted.exchangePublic, pending.exchangePublic) ||
        !_equal(persisted.signingPublic, pending.signingPublic)) {
      throw StateError('Pending device identity changed.');
    }

    // Only public data and cryptographic signatures leave the client.
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('recoveryDeviceEnrollmentCandidate')
        .call({'proof': proof.toWire()});

    final payload = result.data;

    // The server transaction returns {deviceId: ...}.
    // A generic success response must never count as registration.
    if (payload is! Map ||
        payload.length != 1 ||
        payload['deviceId'] != pending.deviceId) {
      throw StateError('Invalid device enrolment acknowledgement.');
    }

    // Verify a fresh server read before reporting registration.
    // The server endpoint does not return private keys.
    final statusResult =
        await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('recoveryDeviceEnrollmentStatus')
            .call({'deviceId': pending.deviceId});

    if (!RecoveryDeviceRegistrationConfirmation.matches(
      value: statusResult.data,
      userUid: uid,
      deviceId: pending.deviceId,
      x25519PublicKey: base64Encode(pending.exchangePublic),
      ed25519PublicKey: base64Encode(pending.signingPublic),
      authorisedByRootDeviceId: record.signed.anchor.deviceId,
      rootFingerprint: record.fingerprint,
    )) {
      throw StateError('Server device registration not verified.');
    }

    // A browser tab or another account may have changed local state.
    final confirmedLocal = await _pending.read(uid);

    if (confirmedLocal == null ||
        confirmedLocal.deviceId != pending.deviceId ||
        !_equal(confirmedLocal.exchangePublic, pending.exchangePublic) ||
        !_equal(confirmedLocal.signingPublic, pending.signingPublic)) {
      throw StateError('Local device changed during confirmation.');
    }

    // No permanent trust pin or trip-key access is granted here.
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Account changed after enrolment.');
    }

    // No local trust pin is created here.
    // No encrypted content is unlocked here.
    // Device and trip-key authorisation must be checked separately.
  }

  bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;

    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }

  User _verifiedUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      throw StateError('Verified sign-in required.');
    }

    return user;
  }

  Future<FirstRootState> inspect() {
    return _bootstrap.inspect();
  }

  Future<PendingRecoveryDeviceIdentity?> readPending() async {
    final user = _verifiedUser();

    final state = await inspect();

    if (!_gate.canPrepare(state)) {
      return null;
    }

    final pending = await _pending.read(user.uid);

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Account changed.');
    }

    return pending;
  }

  /// Creates an untrusted identity on this device only.
  /// Does not replace the original root.
  Future<PendingRecoveryDeviceIdentity> preparePending() async {
    final user = _verifiedUser();

    if (!_gate.canPrepare(await inspect())) {
      throw StateError('Recovery preparation not permitted.');
    }

    final identity = await _pending.prepare(user.uid);

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Account changed.');
    }

    return identity;
  }

  /// Checks the user-held recovery secret locally.
  ///
  /// Recovered root material is not persisted or returned to the UI.
  /// A separate signed enrolment is needed for authorisation.
  Future<void> verifyRecoveryCode(String code) async {
    final user = _verifiedUser();

    if (code.length < 16 || code.length > 4096) {
      throw const FormatException('Invalid recovery code length.');
    }

    if (!_gate.canVerifyRecovery(await inspect())) {
      throw StateError('Recovery verification not permitted.');
    }

    final recovered = await FirstRootRecoveryReadService().recover(
      recoveryCode: code,
    );

    if (recovered.uid != user.uid ||
        FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Recovery account mismatch.');
    }

    // No approval, no local trust pin and no server mutation.
  }
}
