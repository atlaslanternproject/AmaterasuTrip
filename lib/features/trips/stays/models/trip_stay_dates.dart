// Date e orari dei soggiorni: giorni come "AAAA-MM-GG" (senza fuso orario)
// e orari come "HH:MM", gli stessi formati controllati da firestore.rules.

abstract final class TripStayDates {
  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// [day] as YYYY-MM-DD (only year, month and day are used).
  static String format(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// A real calendar day from YYYY-MM-DD, or null.
  static DateTime? parse(Object? raw) {
    if (raw is! String || !_day.hasMatch(raw)) return null;
    final parts = raw.split('-').map(int.parse).toList();
    final day = DateTime(parts[0], parts[1], parts[2]);
    return format(day) == raw ? day : null;
  }

  static bool isValidTime(String? value) =>
      value != null && _time.hasMatch(value);

  /// Nights between check-in and check-out (calendar days).
  static int nights(DateTime checkIn, DateTime checkOut) {
    final start = DateTime.utc(checkIn.year, checkIn.month, checkIn.day);
    final end = DateTime.utc(checkOut.year, checkOut.month, checkOut.day);
    return end.difference(start).inDays;
  }
}
