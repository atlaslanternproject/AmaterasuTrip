// Un luogo salvato del viaggio: nome, categoria, luogo Google o link di
// Google Maps incollato, contatti (telefono, sito), priorità SS/S/A/B,
// visitato, tempo di visita, prezzo d'ingresso (campi del costo comune),
// link dei biglietti, zona, giorno previsto, note e chi l'ha aggiunto.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';
import 'trip_saved_place_category.dart';

class TripSavedPlace implements TripSectionItem {
  const TripSavedPlace({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    required this.category,
    this.place = const TripSectionPlace(),
    this.mapsUrl,
    this.notes,
    this.phone,
    this.website,
    this.priority,
    this.visited = false,
    this.visitMinutes,
    this.ticketsUrl,
    this.area,
    this.plannedDay,
    this.entryPriceMinorUnits,
    this.entryPriceCurrency,
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String name;
  final TripSavedPlaceCategory category;
  final TripSectionPlace place;

  /// Google Maps link pasted by the user, kept as it is.
  final String? mapsUrl;
  final String? notes;

  /// Contacts of the place (filled from Google when chosen there).
  final String? phone;
  final String? website;

  /// Same levels as the bucket list: SS, S, A or B.
  final String? priority;
  final bool visited;

  /// Expected time for the visit, in minutes.
  final int? visitMinutes;
  final String? ticketsUrl;

  /// Area or neighbourhood, to group places close to each other.
  final String? area;

  /// Day when the visit is planned, to group by day.
  final DateTime? plannedDay;

  /// Entry price per person, saved in the common cost fields.
  final int? entryPriceMinorUnits;
  final String? entryPriceCurrency;

  @override
  String? get expenseId => null;

  @override
  String get displayName => name;
}
