// Calcoli sugli orari dei trasporti senza API esterne: scali tra tratte con
// lo stesso codice di prenotazione, apertura del check-in online (voli: 24
// ore prima) e ora entro cui arrivare in aeroporto (voli: 2 ore prima).

import 'trip_transport.dart';
import 'trip_transport_timeline.dart';
import 'trip_transport_type.dart';

class TripTransportLayover {
  const TripTransportLayover(this.minutes, this.place);

  final int minutes;
  final String? place;
}

abstract final class TripTransportSchedule {
  static const flightCheckInHours = 24;
  static const flightAirportMinutes = 120;

  /// Layover before each leg that follows another leg of the same booking
  /// (same booking code), by leg id.
  static Map<String, TripTransportLayover> layovers(List<TripTransport> items) {
    final byCode = <String, List<TripTransport>>{};
    for (final item in items) {
      final code = item.bookingCode?.trim() ?? '';
      if (code.isEmpty || !item.isActive) continue;
      if (TripTransportTimeline.departure(item) == null) continue;
      byCode.putIfAbsent(code.toUpperCase(), () => []).add(item);
    }
    final result = <String, TripTransportLayover>{};
    for (final legs in byCode.values) {
      legs.sort(
        (a, b) => TripTransportTimeline.departure(
          a,
        )!.compareTo(TripTransportTimeline.departure(b)!),
      );
      for (var i = 1; i < legs.length; i++) {
        final arrived = TripTransportTimeline.arrival(legs[i - 1]);
        if (arrived == null) continue;
        result[legs[i].id] = TripTransportLayover(
          TripTransportTimeline.departure(
            legs[i],
          )!.difference(arrived).inMinutes,
          legs[i - 1].to.name,
        );
      }
    }
    return result;
  }

  /// When online check-in opens (null without a departure time or, for
  /// non-flights, without hours set).
  static DateTime? checkInOpens(TripTransport item) {
    final departure = TripTransportTimeline.departure(item);
    final hours =
        item.extras.checkInHoursBefore ??
        (item.type == TripTransportType.flight ? flightCheckInHours : null);
    if (departure == null || hours == null) return null;
    return departure.subtract(Duration(hours: hours));
  }

  /// Local "HH:MM" by which to be at the airport (flights only by default).
  static String? airportBy(TripTransport item) {
    final time = item.departureTime;
    final minutes =
        item.extras.airportMinutesBefore ??
        (item.type == TripTransportType.flight ? flightAirportMinutes : null);
    if (time == null || minutes == null) return null;
    final parts = time.split(':').map(int.tryParse).toList();
    if (parts.length != 2 || parts.contains(null)) return null;
    final total = (parts[0]! * 60 + parts[1]! - minutes) % (24 * 60);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';
  }

  /// Public flight tracking page from the flight number (no API).
  static String? trackingUrl(TripTransport item) {
    final number = item.number?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (item.type != TripTransportType.flight || number.isEmpty) return null;
    return 'https://www.flightaware.com/live/flight/'
        '${Uri.encodeComponent(number.toUpperCase())}';
  }
}
