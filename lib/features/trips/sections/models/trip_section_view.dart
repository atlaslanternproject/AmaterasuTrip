// Modalità di visualizzazione delle sezioni del viaggio, come la bucket
// list e gli alloggi: Card, Elenco o Dettagli. Il codice è il valore
// ricordato nelle preferenze locali del dispositivo.

enum TripSectionView {
  cards('cards'),
  list('list'),
  details('details');

  const TripSectionView(this.code);

  final String code;

  static TripSectionView? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
