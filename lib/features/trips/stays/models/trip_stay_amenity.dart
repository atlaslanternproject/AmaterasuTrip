// Servizi inclusi in un alloggio (facoltativi): colazione, parcheggio,
// Wi-Fi e cucina. Il codice è il valore salvato in Firestore e
// controllato da firestore.rules (campo amenities).

enum TripStayAmenity {
  breakfast('breakfast'),
  parking('parking'),
  wifi('wifi'),
  kitchen('kitchen');

  const TripStayAmenity(this.code);

  /// Value saved in Firestore (see firestore.rules, stays).
  final String code;

  static TripStayAmenity? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }

  /// Known amenities from a saved list, without repeats, in enum order.
  static List<TripStayAmenity> fromCodes(Object? codes) {
    if (codes is! List) return const [];
    final found = codes.map(fromCode).whereType<TripStayAmenity>().toSet();
    return [
      for (final value in values)
        if (found.contains(value)) value,
    ];
  }
}
