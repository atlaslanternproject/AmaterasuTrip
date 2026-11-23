// Un luogo salvato del viaggio: nome, categoria, luogo Google o link di
// Google Maps incollato, note e chi l'ha aggiunto (createdByUid).

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

  @override
  String? get expenseId => null;

  @override
  String get displayName => name;
}
