import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'first_device_bootstrap_policy.dart';

/// Remembers that this installation actually completed account creation.
///
/// This is a client-side flow hint, NOT an independent security proof.
/// Server-side first-root enrolment must independently verify eligibility.
final class FirstRootRegistrationProvenance {
  static const _storageKey = 'amaterasu_first_root_registration_provenance_v1';

  static const _validity = Duration(days: 7);
  static const _clockSkew = Duration(minutes: 5);
  static const _registrationDelay = Duration(minutes: 10);

  /// Pure validation used by both the service and unit tests.
  static bool matches({
    required String expectedUid,
    required String storedUid,
    required int accountCreatedAtMs,
    required int storedCreatedAtMs,
    required int recordedAtMs,
    required int nowMs,
  }) {
    if (expectedUid.isEmpty || expectedUid != storedUid) {
      return false;
    }

    if (accountCreatedAtMs <= 0 ||
        storedCreatedAtMs != accountCreatedAtMs ||
        recordedAtMs <= 0) {
      return false;
    }

    // The marker must originate close to actual account creation.
    if (recordedAtMs < accountCreatedAtMs - _clockSkew.inMilliseconds ||
        recordedAtMs > accountCreatedAtMs + _registrationDelay.inMilliseconds) {
      return false;
    }

    if (accountCreatedAtMs > nowMs + _clockSkew.inMilliseconds ||
        recordedAtMs > nowMs + _clockSkew.inMilliseconds) {
      return false;
    }

    if (nowMs - recordedAtMs > _validity.inMilliseconds ||
        nowMs - accountCreatedAtMs > _validity.inMilliseconds) {
      return false;
    }

    return true;
  }

  /// Called only after successful Firebase account creation.
  Future<void> markCreated(User user) async {
    final createdAt = user.metadata.creationTime;

    if (createdAt == null) {
      await clear();
      return;
    }

    final createdAtMs = createdAt.millisecondsSinceEpoch;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (!matches(
      expectedUid: user.uid,
      storedUid: user.uid,
      accountCreatedAtMs: createdAtMs,
      storedCreatedAtMs: createdAtMs,
      recordedAtMs: nowMs,
      nowMs: nowMs,
    )) {
      await clear();
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final written = await prefs.setString(
      _storageKey,
      jsonEncode({
        'version': 1,
        'uid': user.uid,
        'accountCreatedAtMs': createdAtMs,
        'recordedAtMs': nowMs,
      }),
    );

    if (!written) {
      throw StateError('Registration provenance could not be saved.');
    }
  }

  /// Does not interpret an ordinary Firebase login as registration.
  Future<SecurityAccountEntry> entryFor(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (stored == null) {
      return SecurityAccountEntry.existingSignIn;
    }

    try {
      final decoded = jsonDecode(stored);

      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return SecurityAccountEntry.existingSignIn;
      }

      final createdAt = user.metadata.creationTime;

      if (createdAt == null ||
          decoded['uid'] is! String ||
          decoded['accountCreatedAtMs'] is! int ||
          decoded['recordedAtMs'] is! int) {
        return SecurityAccountEntry.existingSignIn;
      }

      final valid = matches(
        expectedUid: user.uid,
        storedUid: decoded['uid'] as String,
        accountCreatedAtMs: createdAt.millisecondsSinceEpoch,
        storedCreatedAtMs: decoded['accountCreatedAtMs'] as int,
        recordedAtMs: decoded['recordedAtMs'] as int,
        nowMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      );

      return valid
          ? SecurityAccountEntry.createdInCurrentRegistration
          : SecurityAccountEntry.existingSignIn;
    } catch (_) {
      return SecurityAccountEntry.existingSignIn;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
