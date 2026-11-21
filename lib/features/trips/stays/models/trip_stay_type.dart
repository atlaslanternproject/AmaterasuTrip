// Tipo di alloggio (facoltativo): hotel, B&B, appartamento, ostello,
// campeggio o altro. Il codice è il valore salvato in Firestore e
// controllato da firestore.rules.

enum TripStayType {
  hotel('hotel'),
  bnb('bnb'),
  apartment('apartment'),
  hostel('hostel'),
  camping('camping'),
  other('other');

  const TripStayType(this.code);

  /// Value saved in Firestore (see firestore.rules, stays).
  final String code;

  static TripStayType? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
