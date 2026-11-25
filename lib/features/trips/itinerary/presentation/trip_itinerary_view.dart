// Le tre viste dell'Itinerario (linea del tempo, giorno per giorno, mappa)
// e la scelta ricordata sul dispositivo per utente e viaggio, con lo
// stesso schema delle viste delle sezioni (TripSectionViewPreferences).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

enum TripItineraryView {
  timeline(Icons.view_agenda_outlined),
  day(Icons.view_day_outlined),
  map(Icons.map_outlined);

  const TripItineraryView(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    timeline => l10n.itineraryViewTimeline,
    day => l10n.itineraryViewDay,
    map => l10n.itineraryViewMap,
  };
}

abstract final class TripItineraryViewPreferences {
  static String key(String uid, String tripId) =>
      'amaterasu.itinerary.v1.$uid.$tripId.view';

  static Future<TripItineraryView?> load(String uid, String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(key(uid, tripId));
      return TripItineraryView.values.where((v) => v.name == code).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String uid,
    String tripId,
    TripItineraryView v,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key(uid, tripId), v.name);
    } catch (_) {
      // Only a convenience.
    }
  }
}
