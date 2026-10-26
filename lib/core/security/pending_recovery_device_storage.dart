import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pending_recovery_device_identity.dart';
import 'pending_recovery_device_lock.dart';

/// Stores an unapproved device identity locally.
/// Never replaces the trusted root or grants device approval.
final class PendingRecoveryDeviceStorage {
  PendingRecoveryDeviceStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(
              storageNamespace: 'amaterasu_pending_device_v1',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;

  String _key(String uid) {
    PendingRecoveryDeviceIdentity.validateUid(uid);

    return 'pending_recovery_device_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';
  }

  Future<PendingRecoveryDeviceIdentity?> read(String uid) async {
    final raw = await _storage.read(key: _key(uid));

    if (raw == null) return null;

    return PendingRecoveryDeviceIdentity.decodeLocal(raw, expectedUid: uid);
  }

  // Shares concurrent preparation within the same Dart isolate.
  // Does not coordinate independent browser tabs or processes.
  static final Map<String, Future<PendingRecoveryDeviceIdentity>> _inFlight =
      <String, Future<PendingRecoveryDeviceIdentity>>{};

  Future<PendingRecoveryDeviceIdentity> prepare(String uid) {
    PendingRecoveryDeviceIdentity.validateUid(uid);

    final current = _inFlight[uid];
    if (current != null) return current;

    late final Future<PendingRecoveryDeviceIdentity> pending;

    pending = withPendingRecoveryDeviceLock(uid, () => _prepareOnce(uid))
        .whenComplete(() {
          if (identical(_inFlight[uid], pending)) {
            _inFlight.remove(uid);
          }
        });

    _inFlight[uid] = pending;
    return pending;
  }

  Future<PendingRecoveryDeviceIdentity> _prepareOnce(String uid) async {
    // A corrupt record must fail instead of creating new keys.
    final existing = await read(uid);

    if (existing != null) return existing;

    final identity = await PendingRecoveryDeviceIdentity.generate(uid);
    final key = _key(uid);

    // Do not silently overwrite previous key material.
    if (await _storage.read(key: key) != null) {
      throw StateError('Pending device identity already exists.');
    }

    await _storage.write(key: key, value: identity.encodeLocally());

    final verified = await read(uid);

    if (verified == null || verified.deviceId != identity.deviceId) {
      throw StateError('Pending identity persistence failed.');
    }

    return verified;
  }
}
