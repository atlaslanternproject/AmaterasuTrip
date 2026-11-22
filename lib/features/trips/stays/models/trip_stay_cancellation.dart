// Scadenza della cancellazione gratuita di un soggiorno rispetto a oggi:
// ancora lontana, vicina (ultimi giorni: colore di avviso) o già passata.
// Non conta per i soggiorni annullati.

import 'trip_stay.dart';
import 'trip_stay_dates.dart';

enum TripStayCancellationState { open, soon, expired }

abstract final class TripStayCancellation {
  /// Days before the deadline that count as "soon" (deadline day included).
  static const soonDays = 3;

  /// Calendar days from [today] to the last free day (0 = today, negative
  /// = passed); null without a date or when the stay is cancelled.
  static int? daysLeft(TripStay stay, DateTime today) {
    final until = stay.freeCancellationUntil;
    if (until == null || !stay.isActive) return null;
    return TripStayDates.nights(today, until);
  }

  static TripStayCancellationState? state(TripStay stay, DateTime today) {
    final days = daysLeft(stay, today);
    if (days == null) return null;
    if (days < 0) return TripStayCancellationState.expired;
    return days <= soonDays
        ? TripStayCancellationState.soon
        : TripStayCancellationState.open;
  }
}
