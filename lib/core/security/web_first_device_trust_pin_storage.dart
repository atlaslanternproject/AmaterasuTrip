import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'first_device_trust_anchor.dart';

/// Browser-local pin of a previously authenticated first-device root.
///
/// IndexedDB does not defend against malicious same-origin JavaScript,
/// deliberate storage deletion, browser profile resets or rollback.
/// A missing pin must never silently trust a Firestore identity.
class WebFirstDeviceTrustPinStorage {
  WebFirstDeviceTrustPinStorage._(this._database);

  static const _objectStore = 'roots';
  static const defaultDatabaseName = 'amaterasu_trust_pins_v1';

  final web.IDBDatabase _database;
  final FirstDeviceTrustAnchorService _anchors =
      FirstDeviceTrustAnchorService();

  static Future<WebFirstDeviceTrustPinStorage> open({
    String databaseName = defaultDatabaseName,
  }) async {
    if (databaseName.trim().isEmpty) {
      throw ArgumentError('Invalid database name.');
    }

    final request = web.window.indexedDB.open(databaseName, 1);
    final completed = Completer<web.IDBDatabase>();

    request.onupgradeneeded = ((JSAny? _) {
      (request.result as web.IDBDatabase).createObjectStore(_objectStore);
    }).toJS;

    request.onsuccess = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.complete(request.result as web.IDBDatabase);
      }
    }).toJS;

    request.onerror = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.completeError(
          StateError('Cannot open browser trust pin database.'),
        );
      }
    }).toJS;

    request.onblocked = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.completeError(
          StateError('Browser trust pin database is blocked.'),
        );
      }
    }).toJS;

    final database = await completed.future.timeout(
      const Duration(seconds: 20),
    );

    database.onversionchange = ((JSAny? _) {
      database.close();
    }).toJS;

    return WebFirstDeviceTrustPinStorage._(database);
  }

  /// The supplied fingerprint MUST already be independently trusted,
  /// e.g. obtained from a locally generated identity or authenticated
  /// out-of-band verification. It must not be read from the same
  /// untrusted Firebase document being verified.
  Future<void> pinVerifiedRoot({
    required SignedFirstDeviceTrustAnchor signed,
    required String independentlyTrustedFingerprint,
  }) async {
    final anchor = signed.anchor;

    await _anchors.verifyPinned(
      signed: signed,
      expectedUserUid: anchor.userUid,
      expectedDeviceId: anchor.deviceId,
      pinnedFingerprint: independentlyTrustedFingerprint,
    );

    final record = jsonEncode({
      'version': 1,
      'userUid': anchor.userUid,
      'deviceId': anchor.deviceId,
      'fingerprint': independentlyTrustedFingerprint,
    });

    final transaction = _database.transaction(_objectStore.toJS, 'readwrite');

    final completed = Completer<void>();

    transaction.oncomplete = ((JSAny? _) {
      if (!completed.isCompleted) completed.complete();
    }).toJS;

    transaction.onabort = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.completeError(
          StateError('Trust pin already exists or write aborted.'),
        );
      }
    }).toJS;

    transaction.onerror = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.completeError(StateError('Trust pin write failed.'));
      }
    }).toJS;

    // Insert only. Never replace an existing UID's trusted pin.
    transaction.objectStore(_objectStore).add(record.toJS, anchor.userUid.toJS);

    await completed.future.timeout(const Duration(seconds: 20));
  }

  Future<WebPinnedFirstDeviceRoot?> readPin({required String userUid}) async {
    _validateUid(userUid);

    final request = _database
        .transaction(_objectStore.toJS)
        .objectStore(_objectStore)
        .get(userUid.toJS);

    final completed = Completer<JSAny?>();

    request.onsuccess = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.complete(request.result);
      }
    }).toJS;

    request.onerror = ((JSAny? _) {
      if (!completed.isCompleted) {
        completed.completeError(StateError('Trust pin read failed.'));
      }
    }).toJS;

    final value = await completed.future.timeout(const Duration(seconds: 20));

    if (value.isUndefinedOrNull) return null;

    try {
      final raw = (value as JSString).toDart;
      final decoded = jsonDecode(raw);

      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['userUid'] != userUid ||
          decoded['deviceId'] is! String ||
          decoded['fingerprint'] is! String) {
        throw const FormatException('Invalid stored trust pin.');
      }

      final deviceId = decoded['deviceId'] as String;
      final fingerprint = decoded['fingerprint'] as String;

      if (deviceId.trim().isEmpty ||
          deviceId.length > 128 ||
          deviceId.codeUnits.any((code) => code < 32) ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(fingerprint)) {
        throw const FormatException('Invalid trust pin contents.');
      }

      return WebPinnedFirstDeviceRoot(
        deviceId: deviceId,
        fingerprint: fingerprint,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Unreadable browser trust pin.');
    }
  }

  void close() => _database.close();

  void _validateUid(String uid) {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((code) => code < 32)) {
      throw ArgumentError('Invalid user UID.');
    }
  }
}

class WebPinnedFirstDeviceRoot {
  const WebPinnedFirstDeviceRoot({
    required this.deviceId,
    required this.fingerprint,
  });

  final String deviceId;
  final String fingerprint;
}
