// Categoria di un luogo salvato: da vedere, mangiare, shopping, natura,
// vita notturna o altro. Il codice è il valore salvato in Firestore e
// controllato da firestore.rules (savedPlaces).

enum TripSavedPlaceCategory {
  sight('sight'),
  food('food'),
  shopping('shopping'),
  nature('nature'),
  nightlife('nightlife'),
  other('other');

  const TripSavedPlaceCategory(this.code);

  final String code;

  static TripSavedPlaceCategory? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
