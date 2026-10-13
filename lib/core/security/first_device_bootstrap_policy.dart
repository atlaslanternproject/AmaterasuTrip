/// Entry provenance is an application-flow hint, NOT cryptographic
/// evidence that an account has never had a protected identity.
enum SecurityAccountEntry {
  createdInCurrentRegistration,
  existingSignIn,
  restoredSession,
}

enum LocalSecurityIdentity {
  absent,
  pinAndKeysPresent,
  pinPresentKeysMissing,
  invalidOrCorrupted,
}

/// Remote observations are untrusted until cryptographically checked.
enum RemoteSecurityIdentity {
  missing,
  presentUnverified,
  matchesPreviouslyPinnedIdentity,
  conflictsWithPinnedIdentity,
  unavailable,
}

enum ProtectedIdentityAction {
  signedOut,
  continueWithoutProtectedData,
  proposeFirstDeviceSetup,
  requestDeviceApprovalOrRecovery,
  recoverMissingPrivateKeys,
  blockIdentityConflict,
  verifySignedMembershipRevocationAndKeyAccess,
}

/// Pure policy: does not create keys, call Firebase or grant access.
///
/// In particular, proposeFirstDeviceSetup is only permission to start
/// a setup UI. It is NOT permission to register a root automatically.
/// Actual bootstrap needs independent trust establishment, account
/// freshness safeguards and a recovery arrangement.
class FirstDeviceBootstrapPolicy {
  const FirstDeviceBootstrapPolicy();

  ProtectedIdentityAction evaluate({
    required bool authenticated,
    required bool emailVerified,
    required bool userExplicitlyRequestedSetup,
    required SecurityAccountEntry entry,
    required LocalSecurityIdentity local,
    required RemoteSecurityIdentity remote,
  }) {
    if (!authenticated) {
      return ProtectedIdentityAction.signedOut;
    }

    if (local == LocalSecurityIdentity.invalidOrCorrupted ||
        remote == RemoteSecurityIdentity.conflictsWithPinnedIdentity) {
      return ProtectedIdentityAction.blockIdentityConflict;
    }

    if (local == LocalSecurityIdentity.pinPresentKeysMissing) {
      return ProtectedIdentityAction.recoverMissingPrivateKeys;
    }

    if (local == LocalSecurityIdentity.pinAndKeysPresent) {
      if (remote == RemoteSecurityIdentity.matchesPreviouslyPinnedIdentity) {
        // Not an authorization by itself: revocation, trip membership,
        // trusted device state and decryption keys must still be checked.
        return ProtectedIdentityAction
            .verifySignedMembershipRevocationAndKeyAccess;
      }

      return ProtectedIdentityAction.continueWithoutProtectedData;
    }

    // Local pin absent. A remote record cannot become a root of trust.
    if (remote == RemoteSecurityIdentity.unavailable) {
      return ProtectedIdentityAction.continueWithoutProtectedData;
    }

    if (remote != RemoteSecurityIdentity.missing ||
        entry != SecurityAccountEntry.createdInCurrentRegistration) {
      return ProtectedIdentityAction.requestDeviceApprovalOrRecovery;
    }

    if (!emailVerified || !userExplicitlyRequestedSetup) {
      return ProtectedIdentityAction.continueWithoutProtectedData;
    }

    // Only proposes an explicit setup ceremony. Firebase's "missing"
    // answer is insufficient to establish that no root existed before.
    return ProtectedIdentityAction.proposeFirstDeviceSetup;
  }
}
