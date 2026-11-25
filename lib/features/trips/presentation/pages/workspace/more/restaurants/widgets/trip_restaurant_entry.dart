// Ristoranti nelle viste: nome e colore dello stato, fascia di prezzo (€-€€€€)
// e come appare un ristorante (foto Google, luogo, prenotazione, stato,
// cucina, prezzo, note, costo, sito, contatti e mappa).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_stars.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_restaurant_food_labels.dart';

abstract final class TripRestaurantLabels {
  static String status(TripRestaurantStatus s, AppLocalizations l10n) =>
      switch (s) {
        TripRestaurantStatus.toTry => l10n.restaurantStatusToTry,
        TripRestaurantStatus.booked => l10n.restaurantStatusBooked,
        TripRestaurantStatus.tried => l10n.restaurantStatusTried,
      };

  static Color color(TripRestaurantStatus s) => switch (s) {
    TripRestaurantStatus.toTry => AmaterasuColors.accentGold,
    TripRestaurantStatus.booked => AmaterasuColors.success,
    TripRestaurantStatus.tried => AmaterasuColors.accentBudget,
  };

  /// "€€" for level 2.
  static String price(int level) => '€' * level;
}

TripSectionEntry tripRestaurantEntry(
  BuildContext context,
  TripRestaurant item,
) {
  final l10n = AppLocalizations.of(context)!;
  final when = tripSectionWhen(
    context,
    item.reservationDate,
    item.reservationTime,
  );
  final party = item.partySize;
  final highlight = [
    if (when.isNotEmpty)
      item.zoneCity == null ? when : '$when (${item.zoneCity})',
    if (party != null) l10n.restaurantPartyValue(party),
  ].join(' · ');
  final cost = TripSectionLabels.cost(
    item.estimatedCostMinorUnits,
    item.estimatedCostCurrency,
    l10n,
  );
  final address = item.place.address;
  return TripSectionEntry(
    id: item.id,
    icon: Icons.restaurant_rounded,
    title: item.name,
    subtitle: address,
    highlight: highlight.isEmpty ? null : highlight,
    chips: [
      TripSectionChip(
        label: TripRestaurantLabels.status(item.status, l10n),
        color: TripRestaurantLabels.color(item.status),
      ),
      if (item.cuisine case final cuisine?)
        TripSectionChip(
          label: cuisine,
          color: AmaterasuColors.textSecondary,
          icon: Icons.ramen_dining_outlined,
        ),
      if (item.priceLevel case final level?)
        TripSectionChip(
          label: TripRestaurantLabels.price(level),
          color: AmaterasuColors.accentGold,
        ),
      if (item.triedRating case final stars?)
        TripSectionChip(
          key: Key('restaurant-stars-${item.id}'),
          label: tripSectionStars(stars),
          color: AmaterasuColors.accentGold,
        ),
      for (final diet in item.diets)
        TripSectionChip(
          label: TripRestaurantFoodLabels.diet(diet, l10n),
          color: AmaterasuColors.success,
          icon: Icons.eco_outlined,
        ),
      for (final label in item.customCategories)
        TripSectionChip(
          label: label,
          color: AmaterasuColors.textSecondary,
          icon: Icons.label_outline_rounded,
        ),
    ],
    lines: [
      if (item.allergens.isNotEmpty || item.allergenNotes != null)
        TripSectionLine(
          Icons.no_food_outlined,
          [
            if (item.allergens.isNotEmpty)
              l10n.restaurantAllergensValue(
                item.allergens
                    .map((c) => TripRestaurantFoodLabels.allergen(c, l10n))
                    .join(', '),
              ),
            ?item.allergenNotes,
          ].join(' · '),
          key: Key('restaurant-allergens-${item.id}'),
        ),
      if (item.triedNote case final note?)
        TripSectionLine(Icons.rate_review_outlined, note),
      if (cost != null)
        TripSectionLine(
          Icons.payments_outlined,
          cost,
          money: (item.estimatedCostMinorUnits!, item.estimatedCostCurrency!),
          moneyText: l10n.sectionsCostEstimated,
        ),
      if (item.notes case final notes?)
        TripSectionLine(Icons.notes_outlined, notes),
    ],
    links: [
      if (item.website case final site?) (l10n.restaurantWebsite, site),
      ...TripSectionLabels.usefulLinks(item.usefulLinks, l10n),
    ],
    photoPlaceId: item.place.placeId,
    maps: item.place.maps,
    phone: item.phone,
    website: item.website,
  );
}
