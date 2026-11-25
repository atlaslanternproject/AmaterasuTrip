// Un trasporto del viaggio: tipo, da/a (luoghi), partenza e arrivo con
// data, ora e fuso orario, compagnia, numero, codice di prenotazione,
// posti, passeggeri, prenotato su, link, stato, note, costo e spesa.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'trip_transport_extras.dart';
import 'trip_transport_type.dart';

class TripTransport implements TripSectionItem {
  const TripTransport({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.type,
    required this.departureDate,
    this.status = TripBookingStatus.toBook,
    this.from = const TripSectionPlace(),
    this.to = const TripSectionPlace(),
    this.departureTime,
    this.departureOffset,
    this.arrivalDate,
    this.arrivalTime,
    this.arrivalOffset,
    this.carrier,
    this.number,
    this.bookingCode,
    this.seats,
    this.passengerUids = const [],
    this.bookedVia,
    this.bookingUrl,
    this.notes,
    this.extras = const TripTransportExtras(),
    this.estimatedCostMinorUnits,
    this.estimatedCostCurrency,
    this.expenseId,
    this.usefulLinks = const [],
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final TripTransportType type;
  final TripBookingStatus status;
  final TripSectionPlace from;
  final TripSectionPlace to;

  /// Calendar days; times "HH:MM"; offsets from UTC like "+09:00".
  final DateTime departureDate;
  final String? departureTime;
  final String? departureOffset;
  final DateTime? arrivalDate;
  final String? arrivalTime;
  final String? arrivalOffset;

  /// Company (e.g. ITA Airways) and number (e.g. AZ 792).
  final String? carrier;
  final String? number;
  final String? bookingCode;
  final String? seats;
  final List<String> passengerUids;
  final String? bookedVia;
  final String? bookingUrl;
  final String? notes;

  /// Seats per passenger, check-in, airport time, car rental details.
  final TripTransportExtras extras;
  final int? estimatedCostMinorUnits;
  final String? estimatedCostCurrency;
  @override
  final String? expenseId;

  bool get isActive => status.isActive;

  /// "Roma → Tokyo", or the company and number, or empty.
  String get route => [from.name, to.name].whereType<String>().join(' → ');

  /// Useful links (TripSectionLinks), as in the bucket list.
  final List<String> usefulLinks;

  @override
  String get displayName {
    final service = [carrier, number].whereType<String>().join(' ');
    return [service, route].where((part) => part.isNotEmpty).join(' · ');
  }
}
