import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/core/security/local_trust_pin_status.dart';

void main() {
  group('A01 local trust pin', () {
    test('present pin', () async {
      final service = LocalTrustPinStatusService(reader: (_) async => true);

      expect(await service.forUser('user-a'), LocalTrustPinStatus.present);
    });

    test('missing pin', () async {
      final service = LocalTrustPinStatusService(reader: (_) async => false);

      expect(await service.forUser('user-a'), LocalTrustPinStatus.missing);
    });

    test('storage failure fails closed', () async {
      final service = LocalTrustPinStatusService(
        reader: (_) async => throw StateError('Unavailable'),
      );

      expect(await service.forUser('user-a'), LocalTrustPinStatus.unavailable);
    });

    test('invalid UID rejected', () async {
      final service = LocalTrustPinStatusService(reader: (_) async => true);

      await expectLater(service.forUser(''), throwsArgumentError);

      await expectLater(service.forUser('bad\nuid'), throwsArgumentError);
    });
  });
}
