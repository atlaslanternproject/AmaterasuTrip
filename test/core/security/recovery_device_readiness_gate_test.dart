import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/first_root_bootstrap_service.dart';
import 'package:amaterasutrip/core/security/recovery_device_readiness_gate.dart';

void main() {
  const gate = RecoveryDeviceReadinessGate();

  test('Existing root permits recovery preflight', () {
    expect(gate.canPrepare(FirstRootState.approvalOrRecoveryRequired), isTrue);

    expect(
      gate.canVerifyRecovery(FirstRootState.approvalOrRecoveryRequired),
      isTrue,
    );
  });

  test('First-device setup cannot approve another device', () {
    expect(gate.canPrepare(FirstRootState.setupAvailable), isFalse);
    expect(gate.canVerifyRecovery(FirstRootState.setupAvailable), isFalse);
  });

  test('Trusted device cannot silently replace its root', () {
    expect(gate.canPrepare(FirstRootState.activeOnThisDevice), isFalse);
  });

  test('Conflicting identity is blocked', () {
    expect(gate.canPrepare(FirstRootState.blocked), isFalse);
    expect(gate.canVerifyRecovery(FirstRootState.blocked), isFalse);
  });

  test('Unverified authentication cannot prepare a device', () {
    expect(gate.canPrepare(FirstRootState.verificationRequired), isFalse);
  });
}
