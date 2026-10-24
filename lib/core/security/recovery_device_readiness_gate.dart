import 'first_root_bootstrap_service.dart';

/// Only an existing remote root with missing local trust can
/// enter the recovery-device preflight.
///
/// This gate NEVER approves, registers or trusts a device.
final class RecoveryDeviceReadinessGate {
  const RecoveryDeviceReadinessGate();

  bool canPrepare(FirstRootState state) {
    return state == FirstRootState.approvalOrRecoveryRequired;
  }

  bool canVerifyRecovery(FirstRootState state) {
    return state == FirstRootState.approvalOrRecoveryRequired;
  }
}
