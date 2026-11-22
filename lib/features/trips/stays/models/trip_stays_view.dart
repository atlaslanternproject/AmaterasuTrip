// Modalità di visualizzazione degli alloggi, le stesse della bucket list:
// "Card" (card grande con foto), "Elenco" (card compatta con foto
// piccola) e "Dettagli" (una riga essenziale per alloggio).

enum TripStaysView {
  cards('cards'),
  list('list'),
  details('details');

  const TripStaysView(this.code);

  /// Value saved in the local preferences (same codes as the bucket list).
  final String code;

  static TripStaysView? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
