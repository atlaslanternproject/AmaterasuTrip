import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/first_root_server_registration.dart';

void main() {
  Map<String, dynamic> root() => {
    'version': 1,
    'userUid': 'synthetic-user',
    'deviceId': 'synthetic-device',
    'fingerprint': 'synthetic-fingerprint',
    'recovery': {
      'version': 1,
      'salt': 'synthetic-salt',
      'nonce': 'synthetic-nonce',
      'ciphertext': 'synthetic-ciphertext',
      'mac': 'synthetic-mac',
    },
  };

  test('Exact remote root is accepted', () {
    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: root(),
        actual: root(),
      ),
      isTrue,
    );
  });

  test('Null remote root is rejected', () {
    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: root(),
        actual: null,
      ),
      isFalse,
    );
  });

  test('Changed fingerprint is rejected', () {
    final changed = root()..['fingerprint'] = 'forged';

    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: root(),
        actual: changed,
      ),
      isFalse,
    );
  });

  test('Changed encrypted backup is rejected', () {
    final changed = root();
    changed['recovery'] = {
      ...Map<String, dynamic>.from(changed['recovery'] as Map),
      'ciphertext': 'changed',
    };

    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: root(),
        actual: changed,
      ),
      isFalse,
    );
  });

  test('Missing field is rejected', () {
    final changed = root()..remove('signature');

    final expected = root()..['signature'] = 'test-signature';

    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: expected,
        actual: changed,
      ),
      isFalse,
    );
  });

  test('Unexpected field is rejected', () {
    final changed = root()..['unexpected'] = true;

    expect(
      FirstRootServerRegistration.matchesServerRecord(
        expected: root(),
        actual: changed,
      ),
      isFalse,
    );
  });

  test('Matching server receipt is accepted', () {
    expect(
      () => FirstRootServerRegistration.requireReceipt(
        response: {
          'deviceId': 'synthetic-device',
          'fingerprint': 'synthetic-fingerprint',
        },
        deviceId: 'synthetic-device',
        fingerprint: 'synthetic-fingerprint',
      ),
      returnsNormally,
    );
  });

  test('Forged receipt is rejected', () {
    expect(
      () => FirstRootServerRegistration.requireReceipt(
        response: {
          'deviceId': 'other-device',
          'fingerprint': 'synthetic-fingerprint',
        },
        deviceId: 'synthetic-device',
        fingerprint: 'synthetic-fingerprint',
      ),
      throwsStateError,
    );
  });

  test('Only ambiguous server results can trigger a recheck', () {
    expect(FirstRootServerRegistration.mayHaveCommitted('unavailable'), isTrue);
    expect(
      FirstRootServerRegistration.mayHaveCommitted('already-exists'),
      isTrue,
    );
    expect(
      FirstRootServerRegistration.mayHaveCommitted('deadline-exceeded'),
      isTrue,
    );
    expect(
      FirstRootServerRegistration.mayHaveCommitted('permission-denied'),
      isFalse,
    );
    expect(
      FirstRootServerRegistration.mayHaveCommitted('unauthenticated'),
      isFalse,
    );
  });
}
