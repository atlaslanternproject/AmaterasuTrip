// Categoria di una prenotazione: biglietto, ingresso, tour, escursione o
// altro. Il codice è il valore salvato in Firestore e controllato da
// firestore.rules (reservations).

enum TripReservationCategory {
  ticket('ticket'),
  entry('entry'),
  tour('tour'),
  excursion('excursion'),
  other('other');

  const TripReservationCategory(this.code);

  final String code;

  static TripReservationCategory? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
