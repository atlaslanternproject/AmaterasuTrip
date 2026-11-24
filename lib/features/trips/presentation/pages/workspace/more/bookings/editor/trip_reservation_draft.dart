// Stato modificabile dell'editor di una prenotazione: nome, categoria,
// stato, data e ora, luogo, codice, link, partecipanti, regole di
// cancellazione, scadenza, intestatario, biglietti, note e costo. Si
// trasforma in TripReservation.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';

class TripReservationDraft {
  TripReservationDraft({
    TripReservation? initial,
    required String defaultCurrency,
  }) : _initial = initial,
       name = TextEditingController(text: initial?.name ?? ''),
       category = initial?.category ?? TripReservationCategory.ticket,
       status = initial?.status ?? TripBookingStatus.toBook,
       date = initial?.date,
       time = initial?.time,
       place = TripSectionPlaceDraft(
         initial?.place ?? const TripSectionPlace(),
       ),
       bookingCode = TextEditingController(text: initial?.bookingCode ?? ''),
       bookingUrl = TextEditingController(text: initial?.bookingUrl ?? ''),
       policy = TextEditingController(text: initial?.cancellationPolicy ?? ''),
       notes = TextEditingController(text: initial?.notes ?? ''),
       bookBy = initial?.bookBy,
       holder = TextEditingController(text: initial?.holder ?? ''),
       tickets = TextEditingController(
         text: initial?.ticketCount?.toString() ?? '',
       ),
       ticketCode = TextEditingController(text: initial?.ticketCode ?? ''),
       participants = {...?initial?.participantUids},
       cost = TripSectionCostDraft(
         minorUnits: initial?.estimatedCostMinorUnits,
         currency: initial?.estimatedCostCurrency,
         fallback: defaultCurrency,
       );

  final TripReservation? _initial;
  final TextEditingController name;
  TripReservationCategory category;
  TripBookingStatus status;
  DateTime? date;
  String? time;
  final TripSectionPlaceDraft place;
  final TextEditingController bookingCode;
  final TextEditingController bookingUrl;
  final TextEditingController policy;
  final TextEditingController notes;
  DateTime? bookBy;
  final TextEditingController holder;
  final TextEditingController tickets;
  final TextEditingController ticketCode;
  final Set<String> participants;
  final TripSectionCostDraft cost;

  bool get isNew => _initial == null;

  TripReservation toItem({required String tripId, required String authorUid}) {
    String? text(TextEditingController c) => TripSectionFields.clean(c.text);
    final initial = _initial;
    return TripReservation(
      id: initial?.id ?? '',
      tripId: tripId,
      createdByUid: initial?.createdByUid ?? authorUid,
      name: name.text.trim(),
      category: category,
      status: status,
      date: date,
      time: time,
      place: place.toPlace(),
      bookingCode: text(bookingCode),
      bookingUrl: text(bookingUrl),
      participantUids: participants.toList()..sort(),
      cancellationPolicy: text(policy),
      notes: text(notes),
      // The book-by day only matters while the status is "to book".
      bookBy: status == TripBookingStatus.toBook ? bookBy : null,
      holder: text(holder),
      ticketCount: int.tryParse(tickets.text.trim()),
      ticketCode: text(ticketCode),
      estimatedCostMinorUnits: cost.minorUnits,
      estimatedCostCurrency: cost.savedCurrency,
      expenseId: initial?.expenseId,
    );
  }

  void dispose() {
    for (final c in [
      name,
      bookingCode,
      bookingUrl,
      policy,
      notes,
      holder,
      tickets,
      ticketCode,
    ]) {
      c.dispose();
    }
    place.dispose();
    cost.dispose();
  }
}
