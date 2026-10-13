import 'package:amaterasutrip/core/security/first_device_bootstrap_policy.dart';
import 'package:test/test.dart';

void main() {
  const policy = FirstDeviceBootstrapPolicy();

  ProtectedIdentityAction decide({
    bool authenticated = true,
    bool verified = true,
    bool requested = true,
    SecurityAccountEntry entry =
        SecurityAccountEntry.createdInCurrentRegistration,
    LocalSecurityIdentity local = LocalSecurityIdentity.absent,
    RemoteSecurityIdentity remote = RemoteSecurityIdentity.missing,
  }) {
    return policy.evaluate(
      authenticated: authenticated,
      emailVerified: verified,
      userExplicitlyRequestedSetup: requested,
      entry: entry,
      local: local,
      remote: remote,
    );
  }

  test('Account non autenticato: nessun accesso', () {
    expect(decide(authenticated: false), ProtectedIdentityAction.signedOut);
  });

  test('Nuovo account: configurazione non automatica', () {
    expect(
      decide(requested: false),
      ProtectedIdentityAction.continueWithoutProtectedData,
    );
  });

  test('Nuovo account: email non verificata', () {
    expect(
      decide(verified: false),
      ProtectedIdentityAction.continueWithoutProtectedData,
    );
  });

  test('Nuovo account verificato: propone solo configurazione', () {
    expect(decide(), ProtectedIdentityAction.proposeFirstDeviceSetup);
  });

  test('Login esistente: assenza remota non crea nuova identita', () {
    expect(
      decide(entry: SecurityAccountEntry.existingSignIn),
      ProtectedIdentityAction.requestDeviceApprovalOrRecovery,
    );
  });

  test('Sessione ripristinata: assenza remota non crea identita', () {
    expect(
      decide(entry: SecurityAccountEntry.restoredSession),
      ProtectedIdentityAction.requestDeviceApprovalOrRecovery,
    );
  });

  test('Nuovo login con identita remota esistente', () {
    expect(
      decide(remote: RemoteSecurityIdentity.presentUnverified),
      ProtectedIdentityAction.requestDeviceApprovalOrRecovery,
    );
  });

  test('Backend indisponibile: niente bootstrap', () {
    expect(
      decide(remote: RemoteSecurityIdentity.unavailable),
      ProtectedIdentityAction.continueWithoutProtectedData,
    );
  });

  test('Pin locale valido: servono comunque revoca e autorizzazioni', () {
    expect(
      decide(
        local: LocalSecurityIdentity.pinAndKeysPresent,
        remote: RemoteSecurityIdentity.matchesPreviouslyPinnedIdentity,
      ),
      ProtectedIdentityAction.verifySignedMembershipRevocationAndKeyAccess,
    );
  });

  test('Pin locale valido ma radice remota assente', () {
    expect(
      decide(
        local: LocalSecurityIdentity.pinAndKeysPresent,
        remote: RemoteSecurityIdentity.missing,
      ),
      ProtectedIdentityAction.continueWithoutProtectedData,
    );
  });

  test('Pin locale valido ma identita remota non verificata', () {
    expect(
      decide(
        local: LocalSecurityIdentity.pinAndKeysPresent,
        remote: RemoteSecurityIdentity.presentUnverified,
      ),
      ProtectedIdentityAction.continueWithoutProtectedData,
    );
  });

  test('Pin esistente ma chiavi private mancanti', () {
    expect(
      decide(
        local: LocalSecurityIdentity.pinPresentKeysMissing,
        remote: RemoteSecurityIdentity.matchesPreviouslyPinnedIdentity,
      ),
      ProtectedIdentityAction.recoverMissingPrivateKeys,
    );
  });

  test('Pin corrotto: blocco', () {
    expect(
      decide(local: LocalSecurityIdentity.invalidOrCorrupted),
      ProtectedIdentityAction.blockIdentityConflict,
    );
  });

  test('Identita remota discordante: blocco', () {
    expect(
      decide(
        local: LocalSecurityIdentity.pinAndKeysPresent,
        remote: RemoteSecurityIdentity.conflictsWithPinnedIdentity,
      ),
      ProtectedIdentityAction.blockIdentityConflict,
    );
  });

  test('Anche un account appena creato blocca radici discordanti', () {
    expect(
      decide(remote: RemoteSecurityIdentity.conflictsWithPinnedIdentity),
      ProtectedIdentityAction.blockIdentityConflict,
    );
  });

  test('Logout prevale anche su una identita apparentemente valida', () {
    expect(
      decide(
        authenticated: false,
        local: LocalSecurityIdentity.pinAndKeysPresent,
        remote: RemoteSecurityIdentity.matchesPreviouslyPinnedIdentity,
      ),
      ProtectedIdentityAction.signedOut,
    );
  });
}
