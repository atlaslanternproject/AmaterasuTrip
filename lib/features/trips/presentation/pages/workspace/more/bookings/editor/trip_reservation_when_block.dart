// Blocco "Quando e dove" dell'editor di una prenotazione: giorno, ora,
// fuso orario per città (Extra C) e luogo Google. Stesso aspetto di prima,
// spostato qui per tenere l'editor sotto le 200 righe.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/time_zones/amaterasu_zone_field.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/create_trip/destination/services/destination_places_service.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_reservation_draft.dart';

class TripReservationWhenBlock extends StatelessWidget {
  const TripReservationWhenBlock({
    super.key,
    required this.draft,
    required this.places,
    required this.onChanged,
  });

  final TripReservationDraft draft;
  final DestinationPlacesService places;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = draft;
    void set(void Function() change) {
      change();
      onChanged();
    }

    return TripSectionBlock(
      title: l10n.reservationBlockWhenWhere,
      icon: Icons.event_outlined,
      children: [
        TripSectionDayButton(
          fieldKey: 'reservation-day',
          label: l10n.reservationDay,
          value: d.date,
          onChanged: (v) => set(() => d.date = v),
          onClear: () => set(() => d.date = null),
        ),
        TripSectionTimeButton(
          fieldKey: 'reservation-time',
          label: l10n.reservationTime,
          value: d.time,
          onChanged: (v) => set(() => d.time = v),
        ),
        AmaterasuZoneField(
          keyPrefix: 'reservation',
          label: l10n.zoneLabel,
          value: d.zone,
          onChanged: (v) => set(() => d.zone = v),
        ),
        const SizedBox(height: 8),
        TripSectionPlaceField(
          keyPrefix: 'reservation-place',
          label: l10n.reservationPlace,
          draft: d.place,
          places: places,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
