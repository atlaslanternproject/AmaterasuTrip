// Stato modificabile dell'editor di un luogo salvato: luogo o link di
// Google Maps, contatti, categoria, note e dati della visita (priorità,
// visitato, tempo, prezzo d'ingresso, biglietti, zona, giorno). Si
// trasforma in TripSavedPlace.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_links_field.dart';

import 'package:amaterasutrip/features/trips/saved_places/models/trip_maps_link.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_place_field.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_place.dart';

class TripSavedPlaceDraft {
  TripSavedPlaceDraft({TripSavedPlace? initial, required String currency})
    : _initial = initial,
      place = TripSectionPlaceDraft(
        (initial?.place ?? const TripSectionPlace()).withName(initial?.name),
      ),
      link = TextEditingController(text: initial?.mapsUrl),
      notes = TextEditingController(text: initial?.notes),
      phone = TextEditingController(text: initial?.phone),
      website = TextEditingController(text: initial?.website),
      category = initial?.category ?? TripSavedPlaceCategory.sight,
      priority = initial?.priority,
      visited = initial?.visited ?? false,
      minutes = TextEditingController(
        text: initial?.visitMinutes?.toString() ?? '',
      ),
      tickets = TextEditingController(text: initial?.ticketsUrl),
      area = TextEditingController(text: initial?.area),
      plannedDay = initial?.plannedDay,
      price = TripSectionCostDraft(
        minorUnits: initial?.entryPriceMinorUnits,
        currency: initial?.entryPriceCurrency,
        fallback: currency,
      );

  final TripSavedPlace? _initial;
  final TripSectionPlaceDraft place;
  final TextEditingController link;
  final TextEditingController notes;
  final TextEditingController phone;
  final TextEditingController website;
  TripSavedPlaceCategory category;
  String? priority;
  bool visited;
  final TextEditingController minutes;
  final TextEditingController tickets;
  final TextEditingController area;
  DateTime? plannedDay;
  final TripSectionCostDraft price;

  /// Useful links, as in the bucket list.
  late final links = AmaterasuLinksDraft(_initial?.usefulLinks ?? const []);

  bool get isNew => _initial == null;

  /// A pasted Google Maps link fills the empty name and the coordinates.
  void linkChanged(String text) {
    if (!TripMapsLink.isMapsLink(text)) return;
    final parsed = TripMapsLink.parse(text);
    if (place.name.text.trim().isEmpty && parsed.name != null) {
      place.name.text = parsed.name!;
    }
    if (place.placeId == null && parsed.latitude != null) {
      place
        ..latitude = parsed.latitude
        ..longitude = parsed.longitude;
    }
  }

  TripSavedPlace toItem({required String tripId, required String authorUid}) {
    String? text(TextEditingController c) => TripSectionFields.clean(c.text);
    final initial = _initial;
    return TripSavedPlace(
      id: initial?.id ?? '',
      tripId: tripId,
      createdByUid: initial?.createdByUid ?? authorUid,
      name: place.name.text.trim(),
      category: category,
      place: place.toPlace(),
      mapsUrl: text(link),
      notes: text(notes),
      phone: text(phone),
      website: text(website),
      priority: priority,
      visited: visited,
      visitMinutes: int.tryParse(minutes.text.trim()),
      ticketsUrl: text(tickets),
      area: text(area),
      plannedDay: plannedDay,
      entryPriceMinorUnits: price.minorUnits,
      entryPriceCurrency: price.savedCurrency,
      usefulLinks: links.links,
    );
  }

  void dispose() {
    links.dispose();
    for (final c in [link, notes, phone, website, minutes, tickets, area]) {
      c.dispose();
    }
    place.dispose();
    price.dispose();
  }
}
