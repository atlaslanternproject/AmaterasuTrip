import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/recovery_device_registration_confirmation.dart';

void main() {
  const uid = 'test-user';
  const deviceId = 'test-new-device';
  const exchange = 'test-exchange-public-key';
  const signing = 'test-signing-public-key';
  const root = 'test-root-device';
  const fingerprint = 'test-root-fingerprint';

  Map<String, Object?> response() => {
    'active': true,
    'userUid': uid,
    'deviceId': deviceId,
    'x25519PublicKey': exchange,
    'ed25519PublicKey': signing,
    'authorisedByRootDeviceId': root,
    'rootFingerprint': fingerprint,
  };

  bool verify(Object? value) {
    return RecoveryDeviceRegistrationConfirmation.matches(
      value: value,
      userUid: uid,
      deviceId: deviceId,
      x25519PublicKey: exchange,
      ed25519PublicKey: signing,
      authorisedByRootDeviceId: root,
      rootFingerprint: fingerprint,
    );
  }

  test('Accepts matching active registration', () {
    expect(verify(response()), isTrue);
  });

  test('Rejects missing registration', () {
    expect(verify(null), isFalse);
  });

  test('Rejects revoked or inactive device', () {
    final data = response()..['active'] = false;
    expect(verify(data), isFalse);
  });

  test('Rejects another account', () {
    final data = response()..['userUid'] = 'other-user';
    expect(verify(data), isFalse);
  });

  test('Rejects another device ID', () {
    final data = response()..['deviceId'] = 'different';
    expect(verify(data), isFalse);
  });

  test('Rejects swapped exchange key', () {
    final data = response()..['x25519PublicKey'] = 'different';
    expect(verify(data), isFalse);
  });

  test('Rejects swapped signing key', () {
    final data = response()..['ed25519PublicKey'] = 'different';
    expect(verify(data), isFalse);
  });

  test('Rejects changed root binding', () {
    final data = response()..['authorisedByRootDeviceId'] = 'other-root';
    expect(verify(data), isFalse);
  });

  test('Rejects changed root fingerprint', () {
    final data = response()..['rootFingerprint'] = 'other-fingerprint';
    expect(verify(data), isFalse);
  });

  test('Rejects unexpected response fields', () {
    final data = response()..['extra'] = true;
    expect(verify(data), isFalse);
  });
}
