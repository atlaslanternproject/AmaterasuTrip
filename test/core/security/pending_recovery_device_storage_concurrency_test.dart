import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/pending_recovery_device_storage.dart';

class _FakeStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};
  int writes = 0;

  Future<String?> _read(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 15));
    return values[key];
  }

  Future<void> _write(String key, String? value) async {
    writes++;

    await Future<void>.delayed(const Duration(milliseconds: 15));

    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      final key = invocation.namedArguments[#key] as String;
      return _read(key);
    }

    if (invocation.memberName == #write) {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      return _write(key, value);
    }

    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent prepare shares one identity', () async {
    final fake = _FakeStorage();

    final first = PendingRecoveryDeviceStorage(storage: fake);
    final second = PendingRecoveryDeviceStorage(storage: fake);

    const uid = 'b10_3_concurrent_test';

    final results = await Future.wait(
      List.generate(
        8,
        (index) => index.isEven ? first.prepare(uid) : second.prepare(uid),
      ),
    );

    final ids = results.map((value) => value.deviceId).toSet();

    expect(ids, hasLength(1));
    expect(fake.writes, 1);

    final restored = await second.read(uid);

    expect(restored, isNotNull);
    expect(restored!.deviceId, results.first.deviceId);

    final repeated = await first.prepare(uid);

    expect(repeated.deviceId, results.first.deviceId);
    expect(fake.writes, 1);
  });

  test('corrupt identity never triggers silent replacement', () async {
    final fake = _FakeStorage();
    final storage = PendingRecoveryDeviceStorage(storage: fake);

    const uid = 'b10_3_corrupt_test';

    final key =
        'pending_recovery_device_v1_'
        '${base64UrlEncode(utf8.encode(uid))}';

    fake.values[key] = '{corrupt-json';

    await expectLater(storage.prepare(uid), throwsFormatException);

    expect(fake.writes, 0);
    expect(fake.values[key], '{corrupt-json');

    // The failed operation must not remain permanently locked.
    fake.values.remove(key);

    final recovered = await storage.prepare(uid);

    expect(recovered.uid, uid);
    expect(fake.writes, 1);
  });

  test('different UIDs remain independent', () async {
    final fake = _FakeStorage();
    final storage = PendingRecoveryDeviceStorage(storage: fake);

    final results = await Future.wait([
      storage.prepare('b10_3_user_a'),
      storage.prepare('b10_3_user_b'),
    ]);

    expect(results[0].deviceId, isNot(results[1].deviceId));
    expect(fake.writes, 2);
  });
}
