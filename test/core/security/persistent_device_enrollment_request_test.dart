import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/core/security/persistent_device_enrollment_request.dart';

class MemoryStorage {
  final Map<String, String> values = {};
  bool rejectWrite = false;

  Future<String?> read(String key) async => values[key];

  Future<void> write(String key, String value) async {
    if (rejectWrite) throw StateError('Storage unavailable');
    values[key] = value;
  }

  PersistentDeviceEnrollmentRequest get cache =>
      PersistentDeviceEnrollmentRequest(read: read, write: write);
}

final _x = List<int>.generate(32, (i) => i + 1);
final _ed = List<int>.generate(32, (i) => i + 101);
final _now = DateTime.utc(2026, 10, 13, 18, 55);

Future<String> request(
  PersistentDeviceEnrollmentRequest cache, {
  String uid = 'alice',
  String deviceId = 'alice-android',
  List<int>? signingKey,
  DateTime? when,
}) async {
  final value = await cache.obtain(
    uid: uid,
    deviceId: deviceId,
    x25519PublicKey: _x,
    ed25519PublicKey: signingKey ?? _ed,
    nowUtc: when ?? _now,
  );
  return value.toQrPayload();
}

void main() {
  test('first request is saved', () async {
    final storage = MemoryStorage();
    final payload = await request(storage.cache);

    expect(payload, startsWith('amaterasu-enroll-v1:'));
    expect(storage.values.length, 1);
  });

  test('reopening preserves the same challenge', () async {
    final storage = MemoryStorage();

    final first = await request(storage.cache);
    final second = await request(
      storage.cache,
      when: _now.add(const Duration(seconds: 30)),
    );

    expect(second, first);
  });

  test('expired request receives a fresh challenge', () async {
    final storage = MemoryStorage();

    final first = await request(storage.cache);
    final second = await request(
      storage.cache,
      when: _now.add(const Duration(minutes: 4)),
    );

    expect(second, isNot(first));
  });

  test('different account has isolated pending request', () async {
    final storage = MemoryStorage();

    await request(storage.cache);
    await request(storage.cache, uid: 'bob');

    expect(storage.values.length, 2);
  });

  test('device identity substitution is rejected', () async {
    final storage = MemoryStorage();
    await request(storage.cache);

    await expectLater(
      request(storage.cache, deviceId: 'another-device'),
      throwsFormatException,
    );
  });

  test('signing key substitution is rejected', () async {
    final storage = MemoryStorage();
    await request(storage.cache);

    await expectLater(
      request(storage.cache, signingKey: List<int>.filled(32, 55)),
      throwsFormatException,
    );
  });

  test('corrupt stored request is rejected', () async {
    final storage = MemoryStorage();
    await request(storage.cache);
    storage.values[storage.values.keys.single] = 'invalid-json';

    await expectLater(request(storage.cache), throwsFormatException);
  });

  test('failed persistence never reports success', () async {
    final storage = MemoryStorage()..rejectWrite = true;

    await expectLater(request(storage.cache), throwsStateError);
  });
}
