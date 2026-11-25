// Come appare un elemento di una sezione nelle tre viste: icona, titolo,
// sottotitolo, riga evidenziata (date/orari), etichette, righe di
// dettaglio, link, foto Google facoltativa, mappa e contatti.

import 'package:flutter/material.dart';

class TripSectionLine {
  const TripSectionLine(
    this.icon,
    this.text, {
    this.key,
    this.formatted = false,
  });

  final IconData icon;
  final String text;
  final Key? key;

  /// Basic formatting of notes: "# " title, "- " list, **bold**.
  final bool formatted;
}

class TripSectionEntry {
  const TripSectionEntry({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle,
    this.highlight,
    this.chips = const [],
    this.lines = const [],
    this.links = const [],
    this.inactive = false,
    this.photoPlaceId,
    this.maps,
    this.phone,
    this.email,
    this.website,
  });

  final String id;
  final IconData icon;
  final String title;

  /// Place or route, under the title.
  final String? subtitle;

  /// Dates and times, in the accent color.
  final String? highlight;
  final List<Widget> chips;
  final List<TripSectionLine> lines;

  /// (label, url) links, opened with the shared links module.
  final List<(String, String)> links;

  /// Cancelled or done: muted and struck through.
  final bool inactive;

  /// Google place with photos (only for sections with a place).
  final String? photoPlaceId;

  /// Google Maps link, when there is a place.
  final Uri? maps;
  final String? phone;
  final String? email;
  final String? website;
}
