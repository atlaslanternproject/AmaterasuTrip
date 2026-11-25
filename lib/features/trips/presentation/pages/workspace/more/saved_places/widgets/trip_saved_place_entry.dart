// Luoghi salvati nelle viste: nome e icona della categoria e come appare un
// luogo (foto Google, indirizzo, categoria, priorità, visitato, chi l'ha
// aggiunto, giorno e zona, tempo di visita, prezzo d'ingresso, note, link
// di Google Maps e dei biglietti, mappa).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripSavedPlaceLabels {
  static String category(TripSavedPlaceCategory c, AppLocalizations l10n) =>
      switch (c) {
        TripSavedPlaceCategory.sight => l10n.savedPlaceCategorySight,
        TripSavedPlaceCategory.food => l10n.savedPlaceCategoryFood,
        TripSavedPlaceCategory.shopping => l10n.savedPlaceCategoryShopping,
        TripSavedPlaceCategory.nature => l10n.savedPlaceCategoryNature,
        TripSavedPlaceCategory.nightlife => l10n.savedPlaceCategoryNightlife,
        TripSavedPlaceCategory.other => l10n.savedPlaceCategoryOther,
      };

  static IconData icon(TripSavedPlaceCategory c) => switch (c) {
    TripSavedPlaceCategory.sight => Icons.photo_camera_outlined,
    TripSavedPlaceCategory.food => Icons.restaurant_outlined,
    TripSavedPlaceCategory.shopping => Icons.shopping_bag_outlined,
    TripSavedPlaceCategory.nature => Icons.park_outlined,
    TripSavedPlaceCategory.nightlife => Icons.nightlife_outlined,
    TripSavedPlaceCategory.other => Icons.bookmark_outline_rounded,
  };

  /// "1 h 30 min" or "45 min".
  static String duration(int minutes, AppLocalizations l10n) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.savedPlaceMinutesShort(m);
    if (m == 0) return l10n.savedPlaceHoursShort(h);
    return '${l10n.savedPlaceHoursShort(h)} ${l10n.savedPlaceMinutesShort(m)}';
  }
}

TripSectionEntry tripSavedPlaceEntry(
  BuildContext context,
  TripSavedPlace item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  final link = item.mapsUrl;
  final price = TripSectionLabels.money(
    item.entryPriceMinorUnits,
    item.entryPriceCurrency,
  );
  return TripSectionEntry(
    id: item.id,
    icon: TripSavedPlaceLabels.icon(item.category),
    title: item.name,
    subtitle: item.place.address,
    highlight: l10n.savedPlaceAddedBy(nameOf(item.createdByUid)),
    chips: [
      TripSectionChip(
        label: TripSavedPlaceLabels.category(item.category, l10n),
        color: AmaterasuColors.accentGold,
        icon: TripSavedPlaceLabels.icon(item.category),
      ),
      if (item.priority case final priority?)
        TripSectionChip(
          key: Key('saved-place-priority-${item.id}'),
          label: priority,
          color: AmaterasuColors.accentFlame,
        ),
      if (item.visited)
        TripSectionChip(
          key: Key('saved-place-visited-${item.id}'),
          label: l10n.savedPlaceVisited,
          color: AmaterasuColors.success,
          icon: Icons.check_rounded,
        ),
      for (final label in item.customCategories)
        TripSectionChip(
          label: label,
          color: AmaterasuColors.textSecondary,
          icon: Icons.label_outline_rounded,
        ),
    ],
    inactive: item.visited,
    lines: [
      if (item.plannedDay != null || item.area != null)
        TripSectionLine(
          Icons.event_outlined,
          [
            if (item.plannedDay case final day?)
              AmaterasuDates.day(context, day),
            ?item.area,
          ].join(' · '),
        ),
      if (item.visitMinutes case final minutes?)
        TripSectionLine(
          Icons.timelapse_rounded,
          l10n.savedPlaceMinutesValue(
            TripSavedPlaceLabels.duration(minutes, l10n),
          ),
        ),
      if (price != null)
        TripSectionLine(
          Icons.confirmation_number_outlined,
          l10n.savedPlaceEntryPriceValue(price),
          money: (item.entryPriceMinorUnits!, item.entryPriceCurrency!),
          moneyText: l10n.savedPlaceEntryPriceValue,
        ),
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
    links: [
      if (link != null) (l10n.savedPlaceMapsLink, link),
      if (item.ticketsUrl case final tickets?)
        (l10n.savedPlaceTickets, tickets),
      ...TripSectionLabels.usefulLinks(item.usefulLinks, l10n),
    ],
    photoPlaceId: item.place.placeId,
    phone: item.phone,
    website: item.website,
    maps: item.place.maps ?? (link == null ? null : Uri.tryParse(link)),
  );
}
