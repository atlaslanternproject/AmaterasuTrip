// Una prenotazione del viaggio (biglietti, ingressi, tour, escursioni):
// nome, categoria, stato, data e ora, luogo, codice, link, partecipanti,
// regole di cancellazione, scadenza per prenotare, intestatario, biglietti
// (numero e codice da mostrare come QR), note, costo e spesa collegata.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'trip_reservation_category.dart';

class TripReservation implements TripSectionItem {
  const TripReservation({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    required this.category,
    this.status = TripBookingStatus.toBook,
    this.date,
    this.time,
    this.place = const TripSectionPlace(),
    this.bookingCode,
    this.bookingUrl,
    this.participantUids = const [],
    this.cancellationPolicy,
    this.bookBy,
    this.holder,
    this.ticketCount,
    this.ticketCode,
    this.notes,
    this.estimatedCostMinorUnits,
    this.estimatedCostCurrency,
    this.expenseId,
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String name;
  final TripReservationCategory category;
  final TripBookingStatus status;

  /// Calendar day and "HH:MM", both optional.
  final DateTime? date;
  final String? time;
  final TripSectionPlace place;
  final String? bookingCode;
  final String? bookingUrl;
  final List<String> participantUids;

  /// Free text, e.g. "gratis fino a 24 ore prima".
  final String? cancellationPolicy;

  /// Last day to book (useful while the status is "to book").
  final DateTime? bookBy;

  /// Name on the booking and number of tickets.
  final String? holder;
  final int? ticketCount;

  /// Text or code shown as a QR code on the full-screen ticket.
  final String? ticketCode;
  final String? notes;
  final int? estimatedCostMinorUnits;
  final String? estimatedCostCurrency;
  @override
  final String? expenseId;

  bool get isActive => status.isActive;

  @override
  String get displayName => name;
}
