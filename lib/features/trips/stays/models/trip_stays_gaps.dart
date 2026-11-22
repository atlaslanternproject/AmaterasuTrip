// Notti del viaggio senza un alloggio attivo, per un avviso solo
// informativo. La notte di un giorno va da quella sera alla mattina dopo:
// il viaggio dal 10 al 13 ha le notti del 10, 11 e 12.

import 'trip_stay.dart';
import 'trip_stay_dates.dart';

abstract final class TripStaysGaps {
  /// Longer trips are not checked (e.g. dates still missing or wrong).
  static const maxNights = 366;

  /// Nights from [start] to the day before [end] that no active stay covers.
  static List<DateTime> uncoveredNights(
    List<TripStay> stays,
    DateTime start,
    DateTime end,
  ) {
    final total = TripStayDates.nights(start, end);
    if (total <= 0 || total > maxNights) return const [];
    final first = DateTime(start.year, start.month, start.day);
    final result = <DateTime>[];
    for (var i = 0; i < total; i++) {
      final night = DateTime(first.year, first.month, first.day + i);
      final covered = stays.any(
        (stay) =>
            stay.isActive &&
            !night.isBefore(stay.checkInDate) &&
            night.isBefore(stay.checkOutDate),
      );
      if (!covered) result.add(night);
    }
    return result;
  }

  /// Consecutive nights grouped as (first, last).
  static List<(DateTime, DateTime)> ranges(List<DateTime> nights) {
    final result = <(DateTime, DateTime)>[];
    for (final night in nights) {
      if (result.isNotEmpty &&
          TripStayDates.nights(result.last.$2, night) == 1) {
        result.last = (result.last.$1, night);
      } else {
        result.add((night, night));
      }
    }
    return result;
  }
}
