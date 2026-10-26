import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Exclusive lock for pending-device creation on the same Web origin.
///
/// The callback MUST return a JS Promise so the lock remains held
/// across the asynchronous read/generate/write/verify sequence.
///
/// This coordinates cooperating tabs; it does not protect against
/// malicious same-origin JavaScript or erased browser storage.
Future<T> withPendingRecoveryDeviceLock<T>(
  String uid,
  Future<T> Function() action,
) async {
  final manager = web.window.navigator.locks;

  // Fail closed. Never fall back to unlocked key creation on Web.
  if (manager.isUndefinedOrNull) {
    throw StateError('Web Locks API unavailable.');
  }

  final lockName =
      'amaterasu-pending-device-v1-'
      '${base64UrlEncode(utf8.encode(uid))}';

  late T result;
  var completed = false;

  final callback = ((web.Lock? lock) {
    if (lock == null) {
      return Future<void>.error(
        StateError('Exclusive Web lock was not granted.'),
      ).toJS;
    }

    // The JS Promise holds the browser lock until action completes.
    return (() async {
      result = await action();
      completed = true;
    })().toJS;
  }).toJS;

  await manager.request(lockName, callback).toDart;

  if (!completed) {
    throw StateError('Locked operation did not complete.');
  }

  return result;
}
