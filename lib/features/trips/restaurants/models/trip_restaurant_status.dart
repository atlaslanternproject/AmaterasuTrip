// Stato di un ristorante: da provare, prenotato o provato. Il codice è il
// valore salvato in Firestore e controllato da firestore.rules
// (restaurants).

enum TripRestaurantStatus {
  toTry('toTry'),
  booked('booked'),
  tried('tried');

  const TripRestaurantStatus(this.code);

  final String code;

  static TripRestaurantStatus? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
