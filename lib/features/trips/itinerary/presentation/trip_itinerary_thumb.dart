// Miniatura quadrata delle voci di Itinerario e Mappa (icona della sezione
// sul colore delle card; le foto arriveranno con i dati veri) e nome della
// sezione o del tipo di voce.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';

IconData tripItineraryIcon(TripItineraryItem i) =>
    i.section?.icon ??
    (i.kind == TripItineraryKind.freeDay
        ? Icons.wb_sunny_outlined
        : Icons.edit_note_rounded);

String tripItinerarySectionLabel(AppLocalizations l10n, TripItineraryItem i) =>
    i.section?.label(l10n) ??
    (i.kind == TripItineraryKind.freeDay
        ? l10n.itineraryFreeDay
        : l10n.itineraryFreeItem);

/// Square thumbnail: the section icon on the card colour.
class TripItineraryThumb extends StatelessWidget {
  const TripItineraryThumb({super.key, required this.icon, this.size = 52});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AmaterasuColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AmaterasuColors.borderWarm),
    ),
    child: Icon(icon, color: AmaterasuColors.accentBudget),
  );
}
