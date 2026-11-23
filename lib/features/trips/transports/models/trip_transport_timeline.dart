// Orari dei trasporti come istanti reali (data, ora e fuso orario) e avvisi
// solo informativi: coincidenze troppo strette (meno di un'ora) e arrivi
// dopo la partenza del trasporto successivo. Senza fuso si usa UTC.

import 'trip_transport.dart';

class TripTransportWarning {
  const TripTransportWarning(this.first, this.second, this.minutes);

  final TripTransport first;
  final TripTransport second;

  /// Minutes between the arrival of [first] and the departure of
  /// [second]; negative when [first] arrives after [second] leaves.
  final int minutes;

  bool get overlaps => minutes < 0;
}

abstract final class TripTransportTimeline {
  /// Connections shorter than this are "tight".
  static const tightMinutes = 60;

  static DateTime? departure(TripTransport item) =>
      _instant(item.departureDate, item.departureTime, item.departureOffset);

  static DateTime? arrival(TripTransport item) => _instant(
    item.arrivalDate ?? item.departureDate,
    item.arrivalTime,
    item.arrivalOffset,
  );

  /// Minutes of the trip from departure to arrival, when both are known.
  static int? durationMinutes(TripTransport item) {
    final start = departure(item);
    final end = arrival(item);
    if (start == null || end == null) return null;
    return end.difference(start).inMinutes;
  }

  static DateTime? _instant(DateTime day, String? time, String? offset) {
    if (time == null) return null;
    final parts = time.split(':').map(int.tryParse).toList();
    if (parts.length != 2 || parts.contains(null)) return null;
    final local = DateTime.utc(
      day.year,
      day.month,
      day.day,
      parts[0]!,
      parts[1]!,
    );
    return local.subtract(_offset(offset));
  }

  static Duration _offset(String? offset) {
    if (offset == null || offset.length != 6) return Duration.zero;
    final sign = offset.startsWith('-') ? -1 : 1;
    final hours = int.tryParse(offset.substring(1, 3)) ?? 0;
    final minutes = int.tryParse(offset.substring(4, 6)) ?? 0;
    return Duration(minutes: sign * (hours * 60 + minutes));
  }

  /// Warnings between consecutive active transports with known times.
  static List<TripTransportWarning> warnings(List<TripTransport> items) {
    final timed = [
      for (final item in items)
        if (item.isActive && departure(item) != null) item,
    ]..sort((a, b) => departure(a)!.compareTo(departure(b)!));
    final result = <TripTransportWarning>[];
    for (var i = 0; i + 1 < timed.length; i++) {
      final end = arrival(timed[i]);
      if (end == null) continue;
      final gap = departure(timed[i + 1])!.difference(end).inMinutes;
      if (gap < tightMinutes) {
        result.add(TripTransportWarning(timed[i], timed[i + 1], gap));
      }
    }
    return result;
  }
}
