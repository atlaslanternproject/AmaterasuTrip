// Righe e link aggiunti alla card di un trasporto: scalo calcolato, posti
// per passeggero, apertura del check-in online, ora per arrivare in
// aeroporto, noleggio (carburante e franchigia) e "Stato del volo".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_schedule.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_transport_labels.dart';

List<TripSectionLine> tripTransportExtraLines(
  AppLocalizations l10n,
  TripTransport item, {
  required DateTime now,
  required TripTransportLayover? layover,
  required String Function(String uid) nameOf,
}) {
  final extras = item.extras;
  final opens = TripTransportSchedule.checkInOpens(item);
  final airport = TripTransportSchedule.airportBy(item);
  final seats = [
    for (final e in extras.seats.entries)
      if (!e.value.isEmpty) '${nameOf(e.key)} ${e.value.label}',
  ];
  return [
    if (layover != null)
      TripSectionLine(
        Icons.connecting_airports_rounded,
        layover.place == null
            ? l10n.transportLayover(
                TripTransportLabels.duration(layover.minutes),
              )
            : l10n.transportLayoverAt(
                TripTransportLabels.duration(layover.minutes),
                layover.place!,
              ),
        key: Key('transport-layover-${item.id}'),
      ),
    if (seats.isNotEmpty)
      TripSectionLine(
        Icons.event_seat_outlined,
        l10n.transportSeatsValue(seats.join(' · ')),
      ),
    if (opens != null && item.isActive)
      TripSectionLine(
        Icons.how_to_reg_outlined,
        opens.isAfter(now)
            ? l10n.transportCheckInOpensIn(
                TripTransportLabels.duration(opens.difference(now).inMinutes),
              )
            : l10n.transportCheckInOpen,
        key: Key('transport-checkin-${item.id}'),
      ),
    if (airport != null && item.isActive)
      TripSectionLine(
        Icons.flight_takeoff_rounded,
        l10n.transportAirportBy(airport),
      ),
    if (extras.fuelPolicy case final fuel?)
      TripSectionLine(
        Icons.local_gas_station_outlined,
        l10n.transportFuelValue(fuel),
      ),
    if (extras.deductible case final deductible?)
      TripSectionLine(
        Icons.shield_outlined,
        l10n.transportDeductibleValue(deductible),
      ),
  ];
}

List<(String, String)> tripTransportExtraLinks(
  AppLocalizations l10n,
  TripTransport item,
) => [
  if (item.extras.checkInUrl case final url?) (l10n.transportCheckInLink, url),
  if (TripTransportSchedule.trackingUrl(item) case final url?)
    (l10n.transportFlightStatus, url),
];
