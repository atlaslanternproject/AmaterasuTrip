// "Condividi il programma del giorno" come testo (WhatsApp e simili) con
// share_plus, già nel progetto: data, poi una riga per voce con ora, nome,
// luogo e link di Google Maps. Nei test si sostituisce [tripItineraryShare].

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';

/// Sends the text; replaced in tests.
Future<void> Function(String text) tripItineraryShare = (text) =>
    SharePlus.instance.share(ShareParams(text: text));

String tripItineraryDayText(
  BuildContext context,
  DateTime day,
  List<TripItineraryItem> items,
) {
  final l10n = AppLocalizations.of(context)!;
  final lines = [l10n.itineraryShareHeader(AmaterasuDates.day(context, day))];
  for (final i in items) {
    final time = i.time == null
        ? ''
        : '${AmaterasuDates.time(context, i.time!)} ';
    final place = i.place;
    final maps = place == null
        ? null
        : AmaterasuWebLink.googleMaps(
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
          );
    lines.add(
      [
        '• $time${i.actual ?? i.title}',
        if (place != null && place.name != i.title) place.name,
        ?maps?.toString(),
      ].join(' — '),
    );
  }
  return lines.join('\n');
}

Future<void> tripItineraryShareDay(
  BuildContext context,
  DateTime day,
  List<TripItineraryItem> items,
) => tripItineraryShare(tripItineraryDayText(context, day, items));
