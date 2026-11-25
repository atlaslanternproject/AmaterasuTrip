// Ricerche recenti di "Cerca": al massimo 8, nelle preferenze locali del
// dispositivo per utente e viaggio (mai su Firestore), con "Cancella".
// Solo una comodità: se le preferenze non funzionano l'elenco resta vuoto.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed-in user, for the key of the recent searches.
final tripSearchUidProvider = Provider<String?>(
  (ref) => FirebaseAuth.instance.currentUser?.uid,
);

abstract final class TripSearchRecent {
  static const max = 8;

  static String key(String uid, String tripId) =>
      'amaterasu.search.v1.$uid.$tripId.recent';

  static Future<List<String>> load(String? uid, String tripId) async {
    if (uid == null) return const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key(uid, tripId)) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// [query] first, without repeats, at most [max].
  static List<String> add(List<String> list, String query) {
    final text = query.trim();
    if (text.isEmpty) return list;
    return [
      text,
      ...list.where((q) => q.toLowerCase() != text.toLowerCase()),
    ].take(max).toList();
  }

  static Future<void> save(
    String? uid,
    String tripId,
    List<String> list,
  ) async {
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key(uid, tripId), list);
    } catch (_) {
      // Only a convenience.
    }
  }
}
