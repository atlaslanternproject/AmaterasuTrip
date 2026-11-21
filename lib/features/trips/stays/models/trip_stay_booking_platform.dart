// Dove è stato prenotato un soggiorno: Booking, Airbnb, sito dell'alloggio,
// agenzia o altro (con testo libero, fino a 60 caratteri).

enum TripStayBookingPlatform {
  booking('booking'),
  airbnb('airbnb'),
  propertySite('propertySite'),
  agency('agency'),
  other('other');

  const TripStayBookingPlatform(this.code);

  /// Value saved in Firestore (see firestore.rules, stays).
  final String code;

  /// Longest free text for "other", as in firestore.rules.
  static const otherMaxLength = 60;

  static TripStayBookingPlatform? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
