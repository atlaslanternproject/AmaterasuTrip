/// Strict comparison between a server-confirmed device and
/// the locally prepared identity.
///
/// This proves only that registration is present and not revoked
/// at the moment of the server read. It does not unlock trip keys.
abstract final class RecoveryDeviceRegistrationConfirmation {
  static bool matches({
    required Object? value,
    required String userUid,
    required String deviceId,
    required String x25519PublicKey,
    required String ed25519PublicKey,
    required String authorisedByRootDeviceId,
    required String rootFingerprint,
  }) {
    if (value is! Map || value.length != 7) {
      return false;
    }

    return value['active'] == true &&
        value['userUid'] == userUid &&
        value['deviceId'] == deviceId &&
        value['x25519PublicKey'] == x25519PublicKey &&
        value['ed25519PublicKey'] == ed25519PublicKey &&
        value['authorisedByRootDeviceId'] == authorisedByRootDeviceId &&
        value['rootFingerprint'] == rootFingerprint;
  }
}
