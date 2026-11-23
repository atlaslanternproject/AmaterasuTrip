// Stato di un elemento prenotabile (trasporti, prenotazioni): da
// prenotare, prenotato o annullato. Il codice è il valore salvato in
// Firestore e controllato da firestore.rules.

enum TripBookingStatus {
  toBook('toBook'),
  booked('booked'),
  cancelled('cancelled');

  const TripBookingStatus(this.code);

  final String code;

  bool get isActive => this != cancelled;

  static TripBookingStatus? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
