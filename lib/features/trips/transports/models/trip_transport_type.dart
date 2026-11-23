// Tipo di trasporto: volo, treno, bus, traghetto, noleggio auto, transfer o
// altro. Il codice è il valore salvato in Firestore e controllato da
// firestore.rules (transports).

enum TripTransportType {
  flight('flight'),
  train('train'),
  bus('bus'),
  ferry('ferry'),
  carRental('carRental'),
  transfer('transfer'),
  other('other');

  const TripTransportType(this.code);

  final String code;

  static TripTransportType? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
