import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/pending_recovery_device_identity.dart';

void main() {
  group('Pending recovery device identity', () {
    test('01 - New identity has independent key pairs', () async {
      final first = await PendingRecoveryDeviceIdentity.generate('audit-user');

      final second = await PendingRecoveryDeviceIdentity.generate('audit-user');

      expect(first.deviceId, isNot(second.deviceId));
      expect(first.signingPublic, isNot(second.signingPublic));
      expect(first.exchangePublic, isNot(second.exchangePublic));
      expect(first.deviceId, hasLength(43));
    });

    test('02 - Local encode and verified decode', () async {
      final original = await PendingRecoveryDeviceIdentity.generate(
        'audit-user',
      );

      final restored = await PendingRecoveryDeviceIdentity.decodeLocal(
        original.encodeLocally(),
        expectedUid: 'audit-user',
      );

      expect(restored.deviceId, original.deviceId);
      expect(restored.signingPrivate, original.signingPrivate);
      expect(restored.exchangePrivate, original.exchangePrivate);
    });

    test('03 - Another account is rejected', () async {
      final identity = await PendingRecoveryDeviceIdentity.generate(
        'audit-user',
      );

      await expectLater(
        PendingRecoveryDeviceIdentity.decodeLocal(
          identity.encodeLocally(),
          expectedUid: 'another-user',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('04 - Tampered signing public key is rejected', () async {
      final identity = await PendingRecoveryDeviceIdentity.generate(
        'audit-user',
      );

      final data = jsonDecode(identity.encodeLocally()) as Map<String, dynamic>;

      final bytes = base64Decode(data['signingPublic'] as String);
      bytes[0] ^= 1;
      data['signingPublic'] = base64Encode(bytes);

      await expectLater(
        PendingRecoveryDeviceIdentity.decodeLocal(
          jsonEncode(data),
          expectedUid: 'audit-user',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('05 - Invalid key length is rejected', () async {
      final identity = await PendingRecoveryDeviceIdentity.generate(
        'audit-user',
      );

      final data = jsonDecode(identity.encodeLocally()) as Map<String, dynamic>;

      data['exchangePrivate'] = base64Encode([1, 2, 3]);

      await expectLater(
        PendingRecoveryDeviceIdentity.decodeLocal(
          jsonEncode(data),
          expectedUid: 'audit-user',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
