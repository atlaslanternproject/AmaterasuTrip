// Ricorda la modalità di visualizzazione degli alloggi nelle preferenze
// locali del dispositivo, per utente e viaggio, come fa la bucket list
// (nessun dato su Firestore, nessuna regola da cambiare).

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_stays_view.dart';

// TODO(audit): stessa logica di bucket_method_preferences.dart (chiave per utente e viaggio in SharedPreferences); valutare un modulo condiviso delle preferenze di vista.
abstract final class TripStaysViewPreferences {
  static String key(String uid, String tripId) =>
      'amaterasu.stays.v1.$uid.$tripId.view';

  static Future<TripStaysView?> load(String uid, String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    return TripStaysView.fromCode(prefs.getString(key(uid, tripId)));
  }

  static Future<void> save(
    String uid,
    String tripId,
    TripStaysView view,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key(uid, tripId), view.code);
  }
}
