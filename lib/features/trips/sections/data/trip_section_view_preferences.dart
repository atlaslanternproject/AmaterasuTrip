// Ricorda la vista scelta (Card, Elenco, Dettagli) di ogni sezione nelle
// preferenze locali del dispositivo, per utente e viaggio: nessun dato su
// Firestore. Stessa idea di trip_stays_view_preferences.dart.

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_section_view.dart';

abstract final class TripSectionViewPreferences {
  static String key(String section, String uid, String tripId) =>
      'amaterasu.$section.v1.$uid.$tripId.view';

  static Future<TripSectionView?> load(
    String section,
    String uid,
    String tripId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return TripSectionView.fromCode(
        prefs.getString(key(section, uid, tripId)),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String section,
    String uid,
    String tripId,
    TripSectionView view,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key(section, uid, tripId), view.code);
    } catch (_) {
      // Only a convenience: the default view is used next time.
    }
  }
}
