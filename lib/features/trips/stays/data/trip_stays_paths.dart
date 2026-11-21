// Percorsi Firestore dei soggiorni (Hotel/Alloggi):
// trips/{tripId}/stays/{stayId}. Gli identificativi non possono
// contenere "/" né spazi ai bordi.

abstract final class TripStaysPaths {
  static String stays(String tripId) {
    _check(tripId);
    return 'trips/$tripId/stays';
  }

  static String stay(String tripId, String stayId) {
    _check(stayId);
    return '${stays(tripId)}/$stayId';
  }

  static void _check(String value) {
    if (value.trim().isEmpty || value != value.trim() || value.contains('/')) {
      throw ArgumentError.value(value, 'id', 'Invalid document ID');
    }
  }
}
