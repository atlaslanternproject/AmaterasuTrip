// Stato condiviso delle preferenze "Aspetto": parte subito dalla copia nel
// dispositivo, poi legge UNA volta il profilo (nessun ascolto sempre
// attivo); ogni modifica si salva nel dispositivo e nel profilo
// (viaggiatori/{uid}.appearance, controllato da firestore.rules).

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'amaterasu_appearance.dart';

/// Where the preferences of the signed-in user are kept on the server.
abstract interface class AmaterasuAppearanceStore {
  Future<AmaterasuAppearance?> load();
  Future<void> save(AmaterasuAppearance appearance);
}

class FirestoreAppearanceStore implements AmaterasuAppearanceStore {
  FirestoreAppearanceStore(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<AmaterasuAppearance?> load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('viaggiatori').doc(uid).get();
    final raw = doc.data()?['appearance'];
    return raw == null ? null : AmaterasuAppearance.fromMap(raw);
  }

  @override
  Future<void> save(AmaterasuAppearance appearance) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('viaggiatori').doc(uid).update({
      'appearance': appearance.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final amaterasuAppearanceStoreProvider = Provider<AmaterasuAppearanceStore>(
  (ref) => FirestoreAppearanceStore(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

class AmaterasuAppearanceController extends Notifier<AmaterasuAppearance> {
  static const prefsKey = 'appearance.v1';

  @override
  AmaterasuAppearance build() {
    Future.microtask(_restore);
    return const AmaterasuAppearance();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(prefsKey);
      if (local != null) {
        state = AmaterasuAppearance.fromMap(jsonDecode(local));
      }
    } catch (_) {}
    try {
      final remote = await ref.read(amaterasuAppearanceStoreProvider).load();
      if (remote != null && remote != state) {
        state = remote;
        await _saveLocal(remote);
      }
    } catch (_) {
      // Offline or signed out: the copy on the device stays.
    }
  }

  Future<void> _saveLocal(AmaterasuAppearance value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(value.toMap()));
    } catch (_) {}
  }

  /// Applies [value] now and saves it; false when the profile save failed
  /// (the choice still stays on this device).
  Future<bool> update(AmaterasuAppearance value) async {
    state = value;
    await _saveLocal(value);
    try {
      await ref.read(amaterasuAppearanceStoreProvider).save(value);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final amaterasuAppearanceProvider =
    NotifierProvider<AmaterasuAppearanceController, AmaterasuAppearance>(
      AmaterasuAppearanceController.new,
    );
