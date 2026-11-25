// Stato modificabile dell'editor di un ristorante: luogo (il nome del luogo
// è il nome del ristorante), contatti, cucina, fascia di prezzo, stato,
// prenotazione, note e costo. Si trasforma in TripRestaurant.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_categories_block.dart';

import 'package:amaterasutrip/core/time_zones/amaterasu_zone_field.dart';

import 'package:amaterasutrip/core/links/amaterasu_links_field.dart';

import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_food.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';

class TripRestaurantDraft {
  TripRestaurantDraft({
    TripRestaurant? initial,
    required String defaultCurrency,
  }) : _initial = initial,
       place = TripSectionPlaceDraft(
         (initial?.place ?? const TripSectionPlace()).withName(initial?.name),
       ),
       status = initial?.status ?? TripRestaurantStatus.toTry,
       phone = TextEditingController(text: initial?.phone ?? ''),
       website = TextEditingController(text: initial?.website ?? ''),
       cuisine = TextEditingController(text: initial?.cuisine ?? ''),
       priceLevel = initial?.priceLevel,
       reservationDate = initial?.reservationDate,
       reservationTime = initial?.reservationTime,
       partySize = TextEditingController(
         text: initial?.partySize?.toString() ?? '',
       ),
       notes = TextEditingController(text: initial?.notes ?? ''),
       triedRating = initial?.triedRating,
       triedNote = TextEditingController(text: initial?.triedNote ?? ''),
       allergens = {...?initial?.allergens},
       allergenNotes = TextEditingController(
         text: initial?.allergenNotes ?? '',
       ),
       diets = {...?initial?.diets},
       cost = TripSectionCostDraft(
         minorUnits: initial?.estimatedCostMinorUnits,
         currency: initial?.estimatedCostCurrency,
         fallback: defaultCurrency,
       );

  final TripRestaurant? _initial;
  final TripSectionPlaceDraft place;
  TripRestaurantStatus status;
  final TextEditingController phone;
  final TextEditingController website;
  final TextEditingController cuisine;
  int? priceLevel;
  DateTime? reservationDate;
  String? reservationTime;
  final TextEditingController partySize;
  final TextEditingController notes;
  int? triedRating;
  final TextEditingController triedNote;
  final Set<String> allergens;
  final TextEditingController allergenNotes;
  final Set<String> diets;
  final TripSectionCostDraft cost;

  /// Time zone by city (Extra C).
  late AmaterasuZoneValue? zone = _initial?.zone == null
      ? null
      : AmaterasuZoneValue(zone: _initial!.zone!, city: _initial.zoneCity);

  /// Custom categories (Extra D).
  late final categories = TripSectionCategoriesDraft(
    _initial?.customCategories ?? const [],
  );

  /// Useful links, as in the bucket list.
  late final links = AmaterasuLinksDraft(_initial?.usefulLinks ?? const []);

  bool get isNew => _initial == null;

  TripRestaurant toItem({required String tripId, required String authorUid}) {
    String? text(TextEditingController c) => TripSectionFields.clean(c.text);
    final initial = _initial;
    final party = text(partySize);
    return TripRestaurant(
      id: initial?.id ?? '',
      tripId: tripId,
      createdByUid: initial?.createdByUid ?? authorUid,
      name: place.name.text.trim(),
      status: status,
      place: place.toPlace(),
      phone: text(phone),
      website: text(website),
      cuisine: text(cuisine),
      priceLevel: priceLevel,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
      partySize: party == null ? null : (int.tryParse(party) ?? 0),
      notes: text(notes),
      // Stars and note only once the restaurant has been tried.
      triedRating: status == TripRestaurantStatus.tried ? triedRating : null,
      triedNote: status == TripRestaurantStatus.tried ? text(triedNote) : null,
      votes: initial?.votes ?? const {},
      allergens: [
        for (final code in TripRestaurantFood.allergens)
          if (allergens.contains(code)) code,
      ],
      allergenNotes: text(allergenNotes),
      diets: [
        for (final code in TripRestaurantFood.diets)
          if (diets.contains(code)) code,
      ],
      estimatedCostMinorUnits: cost.minorUnits,
      estimatedCostCurrency: cost.savedCurrency,
      expenseId: initial?.expenseId,
      usefulLinks: links.links,
      customCategories: List.of(categories.labels),
      zone: zone?.zone,
      zoneCity: zone?.city,
    );
  }

  void dispose() {
    links.dispose();
    categories.dispose();
    for (final c in [
      phone,
      website,
      cuisine,
      partySize,
      notes,
      triedNote,
      allergenNotes,
    ]) {
      c.dispose();
    }
    place.dispose();
    cost.dispose();
  }
}
