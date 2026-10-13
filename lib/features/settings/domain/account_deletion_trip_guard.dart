/// Temporary protection against orphaned trip membership.
///
/// This does not implement account cleanup or E2EE key revocation.
/// The final solution must run through an authorised backend workflow.
abstract final class AccountDeletionTripGuard {
  static void requireNoTripReferences({
    required bool ownsTrip,
    required bool participatesInTrip,
  }) {
    if (ownsTrip || participatesInTrip) {
      throw StateError(
        'Secure trip cleanup is required before account deletion.',
      );
    }
  }
}
