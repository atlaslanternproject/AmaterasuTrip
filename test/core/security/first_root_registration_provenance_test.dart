import 'package:flutter_test/flutter_test.dart';

import 'package:amaterasutrip/core/security/first_device_bootstrap_policy.dart';
import 'package:amaterasutrip/core/security/first_root_registration_provenance.dart';

void main() {
  const created = 1800000000000;
  const recorded = created + 1000;

  bool valid({
    String expectedUid = 'user-a',
    String storedUid = 'user-a',
    int accountCreatedAtMs = created,
    int storedCreatedAtMs = created,
    int recordedAtMs = recorded,
    int nowMs = created + 60000,
  }) {
    return FirstRootRegistrationProvenance.matches(
      expectedUid: expectedUid,
      storedUid: storedUid,
      accountCreatedAtMs: accountCreatedAtMs,
      storedCreatedAtMs: storedCreatedAtMs,
      recordedAtMs: recordedAtMs,
      nowMs: nowMs,
    );
  }

  test('Fresh registration evidence accepted', () {
    expect(valid(), isTrue);
  });

  test('Different account rejected', () {
    expect(valid(storedUid: 'user-b'), isFalse);
  });

  test('Different Firebase creation timestamp rejected', () {
    expect(valid(storedCreatedAtMs: created + 1000), isFalse);
  });

  test('Evidence created too late rejected', () {
    expect(valid(recordedAtMs: created + 3600000), isFalse);
  });

  test('Expired evidence rejected', () {
    expect(
      valid(nowMs: created + const Duration(days: 8).inMilliseconds),
      isFalse,
    );
  });

  test('Future registration timestamp rejected', () {
    expect(
      valid(nowMs: created - const Duration(hours: 1).inMilliseconds),
      isFalse,
    );
  });

  test('Existing login without fresh registration cannot offer setup', () {
    const policy = FirstDeviceBootstrapPolicy();

    final decision = policy.evaluate(
      authenticated: true,
      emailVerified: true,
      userExplicitlyRequestedSetup: true,
      entry: SecurityAccountEntry.existingSignIn,
      local: LocalSecurityIdentity.absent,
      remote: RemoteSecurityIdentity.missing,
    );

    expect(decision, ProtectedIdentityAction.requestDeviceApprovalOrRecovery);
  });

  test('Current registration may only propose first setup', () {
    const policy = FirstDeviceBootstrapPolicy();

    final decision = policy.evaluate(
      authenticated: true,
      emailVerified: true,
      userExplicitlyRequestedSetup: true,
      entry: SecurityAccountEntry.createdInCurrentRegistration,
      local: LocalSecurityIdentity.absent,
      remote: RemoteSecurityIdentity.missing,
    );

    expect(decision, ProtectedIdentityAction.proposeFirstDeviceSetup);
  });

  test('Remote root never permits a second first-root setup', () {
    const policy = FirstDeviceBootstrapPolicy();

    final decision = policy.evaluate(
      authenticated: true,
      emailVerified: true,
      userExplicitlyRequestedSetup: true,
      entry: SecurityAccountEntry.createdInCurrentRegistration,
      local: LocalSecurityIdentity.absent,
      remote: RemoteSecurityIdentity.presentUnverified,
    );

    expect(decision, isNot(ProtectedIdentityAction.proposeFirstDeviceSetup));
  });
}
