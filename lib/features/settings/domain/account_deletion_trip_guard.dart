// Blocca la cancellazione dell'account se l'utente ha ancora viaggi,
// per non lasciare viaggi senza proprietario. L'errore ha un tipo
// proprio, così la schermata può mostrare un messaggio specifico.

/// Errore lanciato quando l'utente è ancora proprietario o membro di
/// almeno un viaggio. Resta uno [StateError], come prima.
class AccountDeletionBlockedByTripsError extends StateError {
  AccountDeletionBlockedByTripsError()
      : super('Secure trip cleanup is required before account deletion.');
}

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
      throw AccountDeletionBlockedByTripsError();
    }
  }
}
