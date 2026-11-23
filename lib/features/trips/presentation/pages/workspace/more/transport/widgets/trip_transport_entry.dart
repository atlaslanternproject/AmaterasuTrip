// Come appare un trasporto nelle viste: titolo (tipo, compagnia, numero),
// percorso, partenza → arrivo con fuso orario, etichette di stato e tipo,
// durata, posti, codice, prenotato su, passeggeri, costo, note e link.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_timeline.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_transport_labels.dart';

TripSectionEntry tripTransportEntry(
  BuildContext context,
  TripTransport item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  String when(DateTime? day, String? time, String? offset) {
    final text = tripSectionWhen(context, day, time);
    return offset == null || time == null
        ? text
        : '$text (${TripTransportLabels.offset(offset)})';
  }

  final departure = when(
    item.departureDate,
    item.departureTime,
    item.departureOffset,
  );
  final hasArrival = item.arrivalDate != null || item.arrivalTime != null;
  final arrival = when(
    item.arrivalDate ?? item.departureDate,
    item.arrivalTime,
    item.arrivalOffset,
  );
  final minutes = TripTransportTimeline.durationMinutes(item);
  final cost = TripSectionLabels.cost(
    item.estimatedCostMinorUnits,
    item.estimatedCostCurrency,
    l10n,
  );
  final url = item.bookingUrl;
  return TripSectionEntry(
    id: item.id,
    icon: TripTransportLabels.icon(item.type),
    title: TripTransportLabels.title(item, l10n),
    subtitle: item.route.isEmpty ? null : item.route,
    highlight: hasArrival ? '$departure → $arrival' : departure,
    inactive: !item.isActive,
    chips: [TripSectionLabels.statusChip(item.status, l10n)],
    lines: [
      if (minutes != null && minutes >= 0)
        TripSectionLine(
          Icons.timelapse_rounded,
          l10n.transportDuration(TripTransportLabels.duration(minutes)),
        ),
      if (item.seats case final seats?)
        TripSectionLine(
          Icons.event_seat_outlined,
          l10n.transportSeatsValue(seats),
        ),
      if (item.bookingCode case final code?)
        TripSectionLine(
          Icons.confirmation_number_outlined,
          l10n.sectionsBookingCodeValue(code),
        ),
      if (item.bookedVia case final via?)
        TripSectionLine(
          Icons.storefront_outlined,
          l10n.transportBookedViaValue(via),
        ),
      if (item.passengerUids.isNotEmpty)
        TripSectionLine(
          Icons.people_outline,
          l10n.transportPassengersValue(
            item.passengerUids.map(nameOf).join(', '),
          ),
        ),
      if (cost != null)
        TripSectionLine(
          Icons.payments_outlined,
          cost,
          key: Key('transport-cost-${item.id}'),
        ),
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
    links: [if (url != null) (l10n.transportBookingLink, url)],
    maps: item.from.maps ?? item.to.maps,
  );
}
