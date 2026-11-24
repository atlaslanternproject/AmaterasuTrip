// Luoghi salvati nelle viste: nome e icona della categoria e come appare un
// luogo (foto Google, indirizzo, categoria, chi l'ha aggiunto, note, link
// di Google Maps e mappa).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
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
}

TripSectionEntry tripSavedPlaceEntry(
  BuildContext context,
  TripSavedPlace item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  final link = item.mapsUrl;
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
    ],
    lines: [
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
    links: [if (link != null) (l10n.savedPlaceMapsLink, link)],
    photoPlaceId: item.place.placeId,
    phone: item.phone,
    website: item.website,
    maps: item.place.maps ?? (link == null ? null : Uri.tryParse(link)),
  );
}
