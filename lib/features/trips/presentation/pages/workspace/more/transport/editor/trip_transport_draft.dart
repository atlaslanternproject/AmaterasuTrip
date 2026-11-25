// Stato modificabile dell'editor di un trasporto: tipo, stato, luoghi di
// partenza e arrivo, date, orari e fusi, compagnia, posti, passeggeri,
// prenotazione, note e costo. Si trasforma in TripTransport per salvarlo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/time_zones/amaterasu_zone_clock.dart';
import 'package:amaterasutrip/core/time_zones/amaterasu_zone_field.dart';

import 'package:amaterasutrip/core/links/amaterasu_links_field.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_extras.dart';
import 'trip_transport_extras_block.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';

class TripTransportDraft {
  TripTransportDraft({
    TripTransport? initial,
    required DateTime today,
    required String defaultCurrency,
  }) : _initial = initial,
       type = initial?.type ?? TripTransportType.flight,
       status = initial?.status ?? TripBookingStatus.toBook,
       from = TripSectionPlaceDraft(initial?.from ?? const TripSectionPlace()),
       to = TripSectionPlaceDraft(initial?.to ?? const TripSectionPlace()),
       departureDate = initial?.departureDate ?? DateUtils.dateOnly(today),
       departureTime = initial?.departureTime,
       departureOffset = initial?.departureOffset,
       arrivalDate = initial?.arrivalDate,
       arrivalTime = initial?.arrivalTime,
       arrivalOffset = initial?.arrivalOffset,
       carrier = TextEditingController(text: initial?.carrier ?? ''),
       number = TextEditingController(text: initial?.number ?? ''),
       bookingCode = TextEditingController(text: initial?.bookingCode ?? ''),
       seats = TextEditingController(text: initial?.seats ?? ''),
       bookedVia = TextEditingController(text: initial?.bookedVia ?? ''),
       bookingUrl = TextEditingController(text: initial?.bookingUrl ?? ''),
       notes = TextEditingController(text: initial?.notes ?? ''),
       passengers = {...?initial?.passengerUids},
       extras = TripTransportExtrasDraft(
         initial?.extras ?? const TripTransportExtras(),
       ),
       cost = TripSectionCostDraft(
         minorUnits: initial?.estimatedCostMinorUnits,
         currency: initial?.estimatedCostCurrency,
         fallback: defaultCurrency,
       );

  final TripTransport? _initial;
  TripTransportType type;
  TripBookingStatus status;
  final TripSectionPlaceDraft from;
  final TripSectionPlaceDraft to;
  DateTime departureDate;
  String? departureTime;
  String? departureOffset;
  DateTime? arrivalDate;
  String? arrivalTime;
  String? arrivalOffset;
  final TextEditingController carrier;
  final TextEditingController number;
  final TextEditingController bookingCode;
  final TextEditingController seats;
  final TextEditingController bookedVia;
  final TextEditingController bookingUrl;
  final TextEditingController notes;
  final Set<String> passengers;
  final TripTransportExtrasDraft extras;
  final TripSectionCostDraft cost;

  /// Useful links, as in the bucket list.
  late final links = AmaterasuLinksDraft(_initial?.usefulLinks ?? const []);

  /// Time zones chosen by city; when set they give the offsets (Extra C).
  late AmaterasuZoneValue? departureZone = _zone(
    _initial?.extras.departureZone,
    _initial?.extras.departureCity,
  );
  late AmaterasuZoneValue? arrivalZone = _zone(
    _initial?.extras.arrivalZone,
    _initial?.extras.arrivalCity,
  );

  static AmaterasuZoneValue? _zone(String? zone, String? city) =>
      zone == null ? null : AmaterasuZoneValue(zone: zone, city: city);

  /// Offset of the zone on [day]; without a zone the saved offset stays.
  static String? _offset(AmaterasuZoneValue? zone, DateTime? day, String? old) {
    if (zone == null || day == null) return old;
    return AmaterasuZoneClock.offsetOn(zone.zone, day) ?? old;
  }

  bool get isNew => _initial == null;

  TripTransport toItem({required String tripId, required String authorUid}) {
    String? text(TextEditingController c) => TripSectionFields.clean(c.text);
    final initial = _initial;
    return TripTransport(
      id: initial?.id ?? '',
      tripId: tripId,
      createdByUid: initial?.createdByUid ?? authorUid,
      type: type,
      status: status,
      from: from.toPlace(),
      to: to.toPlace(),
      departureDate: departureDate,
      departureTime: departureTime,
      departureOffset: _offset(departureZone, departureDate, departureOffset),
      arrivalDate: arrivalDate,
      arrivalTime: arrivalTime,
      arrivalOffset: _offset(
        arrivalZone,
        arrivalDate ?? departureDate,
        arrivalOffset,
      ),
      carrier: text(carrier),
      number: text(number),
      bookingCode: text(bookingCode),
      seats: text(seats),
      passengerUids: passengers.toList()..sort(),
      bookedVia: text(bookedVia),
      bookingUrl: text(bookingUrl),
      notes: text(notes),
      extras: extras
          .toExtras(passengers)
          .withZones(
            departureZone: departureZone?.zone,
            departureCity: departureZone?.city,
            arrivalZone: arrivalZone?.zone,
            arrivalCity: arrivalZone?.city,
          ),
      estimatedCostMinorUnits: cost.minorUnits,
      estimatedCostCurrency: cost.savedCurrency,
      expenseId: initial?.expenseId,
      usefulLinks: links.links,
    );
  }

  void dispose() {
    links.dispose();
    for (final c in [
      carrier,
      number,
      bookingCode,
      seats,
      bookedVia,
      bookingUrl,
      notes,
    ]) {
      c.dispose();
    }
    extras.dispose();
    from.dispose();
    to.dispose();
    cost.dispose();
  }
}
