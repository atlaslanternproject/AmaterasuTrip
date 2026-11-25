// Eventi del calendario .ics dalle sezioni (tappa 3a): alloggi come
// giornate intere dal check-in al check-out, trasporti con lo scarto UTC
// salvato, prenotazioni e ristoranti con il fuso della città (altrimenti
// ora locale); senza ora giornata intera; annullati esclusi.

import 'package:amaterasutrip/core/time_zones/amaterasu_zone_clock.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/workspace/more/transport/widgets/trip_transport_labels.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_ics_writer.dart';

enum TripIcsCategory { stays, transports, reservations, restaurants }

/// "+02:00" of an IANA zone on a day, or null.
typedef TripIcsOffsetOf = String? Function(String zone, DateTime day);

class TripIcsEvents {
  TripIcsEvents(this.l10n, {TripIcsOffsetOf? offsetOf})
    : offsetOf = offsetOf ?? AmaterasuZoneClock.offsetOn;

  final AppLocalizations l10n;
  final TripIcsOffsetOf offsetOf;

  static const _hour = Duration(hours: 1);
  static const _day = Duration(days: 1);
  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
  static final _offset = RegExp(r'^([+-])(\d{2}):(\d{2})$');

  /// The moment of [day] at [hhmm] in the place: UTC when the offset is
  /// known (saved, or from [zone]), else local time; no time: whole day.
  TripIcsTime? at(DateTime? day, String? hhmm, {String? offset, String? zone}) {
    if (day == null) return null;
    final date = DateTime.utc(day.year, day.month, day.day);
    final clock = _hhmm.firstMatch(hhmm ?? '');
    if (clock == null) return TripIcsTime.day(date);
    final wall = date.add(
      Duration(hours: int.parse(clock[1]!), minutes: int.parse(clock[2]!)),
    );
    final off = _offset.firstMatch(
      offset ?? (zone == null ? '' : offsetOf(zone, day) ?? ''),
    );
    if (off == null) return TripIcsTime.local(wall);
    final shift = Duration(
      hours: int.parse(off[2]!),
      minutes: int.parse(off[3]!),
    );
    return TripIcsTime.utc(
      off[1] == '-' ? wall.add(shift) : wall.subtract(shift),
    );
  }

  /// [end] when it is after [start], otherwise one hour (or one day) later.
  static TripIcsTime _end(TripIcsTime start, TripIcsTime? end) {
    final fallback = start.plus(
      start.kind == TripIcsTimeKind.day ? _day : _hour,
    );
    if (end == null || end.kind != start.kind) return fallback;
    return end.value.isAfter(start.value) ? end : fallback;
  }

  static String? _place(TripSectionPlace p) => p.name ?? p.address;

  String? _code(String? code) =>
      code == null || code.trim().isEmpty ? null : l10n.exportIcsCode(code);

  List<TripIcsEvent> stays(List<TripStay> items) => [
    for (final s in items)
      if (s.status != TripStayStatus.cancelled)
        TripIcsEvent(
          uid: 'stay-${s.id}@amaterasutrip',
          summary: s.name,
          start: at(s.checkInDate, null)!,
          end: _end(at(s.checkInDate, null)!, at(s.checkOutDate, null)),
          location: s.address ?? s.city,
          description: [
            if (s.checkInTime != null) l10n.exportIcsCheckIn(s.checkInTime!),
            if (s.checkOutTime != null) l10n.exportIcsCheckOut(s.checkOutTime!),
          ].join('\n'),
        ),
  ];

  List<TripIcsEvent> transports(List<TripTransport> items) => [
    for (final t in items)
      if (t.status != TripBookingStatus.cancelled)
        if (at(
              t.departureDate,
              t.departureTime,
              offset: t.departureOffset,
              zone: t.extras.departureZone,
            )
            case final start?)
          TripIcsEvent(
            uid: 'transport-${t.id}@amaterasutrip',
            summary: [
              TripTransportLabels.title(t, l10n),
              t.route,
            ].where((p) => p.isNotEmpty).join(' · '),
            start: start,
            end: _end(
              start,
              t.arrivalTime == null
                  ? null
                  : at(
                      t.arrivalDate ?? t.departureDate,
                      t.arrivalTime,
                      offset: t.arrivalOffset,
                      zone: t.extras.arrivalZone,
                    ),
            ),
            location: _place(t.from),
            description: _code(t.bookingCode),
          ),
  ];

  List<TripIcsEvent> reservations(List<TripReservation> items) => [
    for (final r in items)
      if (r.status != TripBookingStatus.cancelled)
        if (at(r.date, r.time, zone: r.zone) case final start?)
          TripIcsEvent(
            uid: 'reservation-${r.id}@amaterasutrip',
            summary: r.name,
            start: start,
            end: _end(start, null),
            location: _place(r.place),
            description: _code(r.bookingCode),
          ),
  ];

  List<TripIcsEvent> restaurants(List<TripRestaurant> items) => [
    for (final r in items)
      if (at(r.reservationDate, r.reservationTime, zone: r.zone)
          case final start?)
        TripIcsEvent(
          uid: 'restaurant-${r.id}@amaterasutrip',
          summary: r.name,
          start: start,
          end: _end(start, null),
          location: _place(r.place),
        ),
  ];
}
