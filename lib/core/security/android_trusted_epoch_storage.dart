import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pinned_trip_epoch_store.dart';

/// Android encrypted storage for E2EE trusted epochs.
///
/// Do not activate for production until Android backup exclusions
/// are configured and recovery/multi-device flows are verified.
final class AndroidTrustedEpochStorage implements TrustedEpochRecordStorage {
  AndroidTrustedEpochStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          FlutterSecureStorage(
            aOptions: const AndroidOptions(
              storageNamespace: 'amaterasu_health_keys_v1',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;

  void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Android E2EE secure storage required.');
    }
  }

  @override
  Future<String?> read(String key) async {
    _requireAndroid();
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    _requireAndroid();
    await _storage.write(key: key, value: value);
  }
}
