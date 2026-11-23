// Prenotazioni nelle viste: nome e icona della categoria e come appare una
// prenotazione (luogo, data e ora, stato e categoria, codice, partecipanti,
// regole di cancellazione, costo, note, link e foto del luogo Google).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripReservationLabels {
  static String category(TripReservationCategory c, AppLocalizations l10n) =>
      switch (c) {
        TripReservationCategory.ticket => l10n.reservationCategoryTicket,
        TripReservationCategory.entry => l10n.reservationCategoryEntry,
        TripReservationCategory.tour => l10n.reservationCategoryTour,
        TripReservationCategory.excursion => l10n.reservationCategoryExcursion,
        TripReservationCategory.other => l10n.reservationCategoryOther,
      };

  static IconData icon(TripReservationCategory c) => switch (c) {
    TripReservationCategory.ticket => Icons.local_activity_outlined,
    TripReservationCategory.entry => Icons.museum_outlined,
    TripReservationCategory.tour => Icons.tour_outlined,
    TripReservationCategory.excursion => Icons.hiking_rounded,
    TripReservationCategory.other => Icons.confirmation_number_outlined,
  };
}

TripSectionEntry tripReservationEntry(
  BuildContext context,
  TripReservation item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  final when = tripSectionWhen(context, item.date, item.time);
  final cost = TripSectionLabels.cost(
    item.estimatedCostMinorUnits,
    item.estimatedCostCurrency,
    l10n,
  );
  final url = item.bookingUrl;
  final place = [
    item.place.name,
    item.place.address,
  ].whereType<String>().toSet().join(' · ');
  return TripSectionEntry(
    id: item.id,
    icon: TripReservationLabels.icon(item.category),
    title: item.name,
    subtitle: place.isEmpty ? null : place,
    highlight: when.isEmpty ? null : when,
    inactive: !item.isActive,
    chips: [
      TripSectionLabels.statusChip(item.status, l10n),
      TripSectionChip(
        label: TripReservationLabels.category(item.category, l10n),
        color: AmaterasuColors.accentGold,
        icon: TripReservationLabels.icon(item.category),
      ),
    ],
    lines: [
      if (item.bookingCode case final code?)
        TripSectionLine(
          Icons.confirmation_number_outlined,
          l10n.sectionsBookingCodeValue(code),
        ),
      if (item.participantUids.isNotEmpty)
        TripSectionLine(
          Icons.people_outline,
          l10n.reservationParticipantsValue(
            item.participantUids.map(nameOf).join(', '),
          ),
        ),
      if (item.cancellationPolicy case final policy?)
        TripSectionLine(
          Icons.event_busy_outlined,
          l10n.reservationPolicyValue(policy),
        ),
      if (cost != null) TripSectionLine(Icons.payments_outlined, cost),
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
    links: [if (url != null) (l10n.reservationLink, url)],
    photoPlaceId: item.place.placeId,
    maps: item.place.maps,
  );
}
