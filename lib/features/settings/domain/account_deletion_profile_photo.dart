// Cancellazione dell'account: decide quale foto del profilo cancellare
// da Storage. Solo un percorso dentro users/{uid}/profile/ è considerato
// la foto di questo utente; altrimenti non si cancella nulla.

abstract final class AccountDeletionProfilePhoto {
  /// Percorso Storage della foto da cancellare, oppure null se non ce n'è
  /// una (campo assente o vuoto) o se il percorso non è dell'utente.
  static String? pathToDelete({
    required String uid,
    required Map<String, dynamic>? profileData,
  }) {
    final raw = profileData?['photoPath'];

    if (raw is! String) {
      return null;
    }

    final path = raw.trim();
    final prefix = 'users/$uid/profile/';

    if (uid.isEmpty || uid.contains('/') || !path.startsWith(prefix)) {
      return null;
    }

    final fileName = path.substring(prefix.length);

    if (fileName.isEmpty || fileName.contains('/')) {
      return null;
    }

    return path;
  }
}
