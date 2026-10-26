import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'signed_trip_device_roster.dart';
import 'verified_trip_rotation_reader.dart';

/// Persistence must be independent of Firebase.
/// Failures must throw. Null is allowed only when no record exists.
abstract interface class TrustedEpochRecordStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Account-scoped, trip-scoped local trust state.
///
/// Bootstrap requires an independently pinned signing key and a
/// correctly signed roster. There is no Firebase trust fallback.
///
/// Per-instance writes are serialised. The production adapter must
/// additionally address concurrent processes and storage rollback.
final class PinnedTripEpochStore implements TrustedTripEpochStore {
  factory PinnedTripEpochStore({
    required String uid,
    required TrustedEpochRecordStorage storage,
  }) {
    return PinnedTripEpochStore._(_checkId(uid), storage);
  }

  PinnedTripEpochStore._(this._uid, this._storage);

  final String _uid;
  final TrustedEpochRecordStorage _storage;

  Future<void> _tail = Future<void>.value();

  static String _checkId(String value) {
    if (value.trim().isEmpty ||
        value.trim() != value ||
        value.length > 128 ||
        value.contains('/') ||
        value == '.' ||
        value == '..' ||
        value.codeUnits.any((c) => c < 32)) {
      throw ArgumentError('Invalid E2EE trust identifier.');
    }
    return value;
  }

  String _key(String tripId) {
    final trip = _checkId(tripId);
    return 'trusted_epoch_v1:${base64UrlEncode(utf8.encode(_uid))}:'
        '${base64UrlEncode(utf8.encode(trip))}';
  }

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final completed = Completer<void>();
    _tail = completed.future;

    await previous;
    try {
      return await operation();
    } finally {
      completed.complete();
    }
  }

  Future<Map<String, dynamic>?> _readRecord(String tripId) async {
    final raw = await _storage.read(_key(tripId));

    if (raw == null) return null;

    try {
      final value = jsonDecode(raw);

      if (value is! Map<String, dynamic> ||
          value.length != 5 ||
          value['version'] != 1 ||
          value['uid'] != _uid ||
          value['tripId'] != tripId ||
          value['epoch'] is! int ||
          value['epoch'] < 2 ||
          value['epoch'] >= 2147483647 ||
          value['authorityPin'] is! String ||
          !RegExp(
            r'^[A-Za-z0-9_-]{43}$',
          ).hasMatch(value['authorityPin'] as String)) {
        throw const FormatException('Invalid trusted E2EE epoch record.');
      }

      return value;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Corrupted trusted E2EE epoch record.');
    }
  }

  /// Bootstrap is only for a device being explicitly enrolled.
  ///
  /// The pinned authority key must already have been authenticated
  /// independently of Firestore. Missing local state after a reset
  /// requires recovery, not automatic re-enrolment.
  Future<void> bootstrapFromVerifiedRoster({
    required String tripId,
    required SignedTripDeviceRoster roster,
    required String authorityUid,
    required String authorityDeviceId,
    required SimplePublicKey independentlyPinnedAuthority,
  }) async {
    await _exclusive(() async {
      final checkedTrip = _checkId(tripId);

      if (await _readRecord(checkedTrip) != null) {
        throw StateError('This trip already has a trusted E2EE epoch.');
      }

      if (roster.tripId != checkedTrip ||
          independentlyPinnedAuthority.type != KeyPairType.ed25519) {
        throw StateError('Invalid E2EE trust bootstrap.');
      }

      await SignedTripDeviceRosterVerifier().verify(
        roster: roster,
        expectedTripId: checkedTrip,
        expectedAuthorityUid: authorityUid,
        expectedAuthorityDeviceId: authorityDeviceId,
        minimumTrustedEpoch: 2,
        pinnedAuthorityEd25519: independentlyPinnedAuthority,
      );

      final digest = await Sha256().hash(independentlyPinnedAuthority.bytes);

      final pin = base64UrlEncode(digest.bytes).replaceAll('=', '');

      await _storage.write(
        _key(checkedTrip),
        jsonEncode({
          'version': 1,
          'uid': _uid,
          'tripId': checkedTrip,
          'epoch': roster.epoch,
          'authorityPin': pin,
        }),
      );

      final saved = await _readRecord(checkedTrip);

      if (saved == null ||
          saved['epoch'] != roster.epoch ||
          saved['authorityPin'] != pin) {
        throw StateError('Trusted E2EE bootstrap persistence failed.');
      }
    });
  }

  @override
  Future<int?> readTrustedFloor(String tripId) async {
    final checkedTrip = _checkId(tripId);
    return (await _readRecord(checkedTrip))?['epoch'] as int?;
  }

  @override
  Future<void> advanceTrustedFloor(String tripId, int verifiedEpoch) async {
    await _exclusive(() async {
      final checkedTrip = _checkId(tripId);

      if (verifiedEpoch < 2 || verifiedEpoch >= 2147483647) {
        throw StateError('Invalid verified E2EE epoch.');
      }

      final current = await _readRecord(checkedTrip);

      if (current == null) {
        throw StateError('Device E2EE trust bootstrap is missing.');
      }

      final previous = current['epoch'] as int;

      if (verifiedEpoch < previous) {
        throw StateError('Trusted E2EE epoch regression refused.');
      }

      if (verifiedEpoch == previous) return;

      await _storage.write(
        _key(checkedTrip),
        jsonEncode({...current, 'epoch': verifiedEpoch}),
      );

      if (await readTrustedFloor(checkedTrip) != verifiedEpoch) {
        throw StateError('Trusted E2EE epoch persistence failed.');
      }
    });
  }
}
