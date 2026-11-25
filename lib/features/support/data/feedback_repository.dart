// Invio di "Segnala un problema" e "Suggerisci un'idea" (Extra F): un
// documento in feedback/{uid}_{giorno UTC}_{1..5}, solo testo, tipo,
// versione e lingua. Le regole permettono al massimo 5 invii al giorno e
// nessuna lettura dall'app. Nessun registro errori, nessuna statistica.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedbackKind { bug, idea }

enum FeedbackResult { sent, dailyLimit, failed }

abstract interface class FeedbackRepository {
  Future<FeedbackResult> send(
    FeedbackKind kind,
    String text, {
    required String appVersion,
    required String language,
  });
}

class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const dailyMax = 5;
  static const textMax = 2000;

  /// Day of the server clock (UTC) used by the rules in the id.
  static String day(DateTime now) {
    final utc = now.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${utc.year}-${two(utc.month)}-${two(utc.day)}';
  }

  @override
  Future<FeedbackResult> send(
    FeedbackKind kind,
    String text, {
    required String appVersion,
    required String language,
  }) async {
    final uid = _auth.currentUser?.uid;
    final clean = text.trim();
    if (uid == null || clean.isEmpty || clean.length > textMax) {
      return FeedbackResult.failed;
    }
    final today = day(DateTime.now());
    // A used slot is refused by the rules (no overwrite): try the next.
    for (var n = 1; n <= dailyMax; n++) {
      try {
        await _db.collection('feedback').doc('${uid}_${today}_$n').set({
          'kind': kind.name,
          'text': clean,
          'appVersion': appVersion,
          'language': language == 'it' ? 'it' : 'en',
          'createdByUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return FeedbackResult.sent;
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') return FeedbackResult.failed;
      } catch (_) {
        return FeedbackResult.failed;
      }
    }
    return FeedbackResult.dailyLimit;
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FirestoreFeedbackRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);
