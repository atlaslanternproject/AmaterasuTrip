// Un ristorante del viaggio: nome e luogo Google (con telefono e sito),
// cucina, fascia di prezzo, stato, prenotazione (data, ora, persone), voti
// dei viaggiatori, allergeni da segnalare, diete, voto e nota di chi l'ha
// provato, note, costo e spesa.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'trip_restaurant_status.dart';

class TripRestaurant implements TripSectionItem {
  const TripRestaurant({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    this.status = TripRestaurantStatus.toTry,
    this.place = const TripSectionPlace(),
    this.phone,
    this.website,
    this.cuisine,
    this.priceLevel,
    this.reservationDate,
    this.reservationTime,
    this.partySize,
    this.notes,
    this.votes = const {},
    this.allergens = const [],
    this.allergenNotes,
    this.diets = const [],
    this.triedRating,
    this.triedNote,
    this.estimatedCostMinorUnits,
    this.estimatedCostCurrency,
    this.expenseId,
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String name;
  final TripRestaurantStatus status;
  final TripSectionPlace place;
  final String? phone;
  final String? website;

  /// Free text, e.g. "Ramen" or "Kaiseki".
  final String? cuisine;

  /// 1 (€) to 4 (€€€€).
  final int? priceLevel;
  final DateTime? reservationDate;
  final String? reservationTime;
  final int? partySize;
  final String? notes;

  /// Traveler uid -> priority (SS, S, A, B); saved apart from the edits.
  final Map<String, String> votes;

  /// EU allergens to tell the restaurant about (codes of
  /// TripRestaurantFood.allergens) and a free note.
  final List<String> allergens;
  final String? allergenNotes;

  /// Diet labels (vegetarian, vegan, halal, kosher, glutenFree).
  final List<String> diets;

  /// Once tried: stars from 1 to 5 and a short note.
  final int? triedRating;
  final String? triedNote;
  final int? estimatedCostMinorUnits;
  final String? estimatedCostCurrency;
  @override
  final String? expenseId;

  @override
  String get displayName => name;
}
