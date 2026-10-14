import 'local_trust_pin_reader_stub.dart'
    if (dart.library.io) 'local_trust_pin_reader_io.dart'
    if (dart.library.js_interop) 'local_trust_pin_reader_web.dart'
    as platform;

enum LocalTrustPinStatus { present, missing, unavailable }

typedef LocalTrustPinReader = Future<bool> Function(String uid);

class LocalTrustPinStatusService {
  LocalTrustPinStatusService({LocalTrustPinReader? reader})
    : _reader = reader ?? platform.readLocalTrustPin;

  final LocalTrustPinReader _reader;

  Future<LocalTrustPinStatus> forUser(String uid) async {
    if (uid.trim().isEmpty ||
        uid.length > 128 ||
        uid.codeUnits.any((value) => value < 32)) {
      throw ArgumentError('Invalid user UID.');
    }

    try {
      final exists = await _reader(uid);
      return exists ? LocalTrustPinStatus.present : LocalTrustPinStatus.missing;
    } catch (_) {
      // Storage failure must never trigger automatic trust.
      return LocalTrustPinStatus.unavailable;
    }
  }
}
