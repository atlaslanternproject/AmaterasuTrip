// Stato di un soggiorno (Hotel/Alloggi): prenotato, da confermare o
// annullato. "Annullato" resta un soggiorno visibile, non una cancellazione.

enum TripStayStatus {
  booked('booked'),
  toConfirm('toConfirm'),
  cancelled('cancelled');

  const TripStayStatus(this.code);

  /// Value saved in Firestore (see firestore.rules, stays).
  final String code;

  /// An active stay counts for date overlaps; a cancelled one does not.
  bool get isActive => this != TripStayStatus.cancelled;

  static TripStayStatus? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
