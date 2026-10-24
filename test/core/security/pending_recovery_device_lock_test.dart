import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/core/security/pending_recovery_device_lock.dart';

void main() {
  test('B10.4 - exclusive lock serializes asynchronous operations', () async {
    final events = <String>[];
    const uid = 'b10_4_web_lock_test';

    final first = withPendingRecoveryDeviceLock(uid, () async {
      events.add('first-start');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      events.add('first-end');
      return 1;
    });

    final second = withPendingRecoveryDeviceLock(uid, () async {
      events.add('second-start');
      events.add('second-end');
      return 2;
    });

    final values = await Future.wait([first, second]);

    expect(values, [1, 2]);
    expect(events, ['first-start', 'first-end', 'second-start', 'second-end']);
  }, skip: !kIsWeb);
}
