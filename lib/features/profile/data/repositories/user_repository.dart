import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository(this._firestore);
  Future<void> createUsername({
    required String username,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(
        'Nessun utente autenticato',
      );
    }
    final normalizedUsername =
        username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      throw Exception(
        'Username non può² essere vuoto',
      );
    }
    final usernameRef =
        _firestore
            .collection('usernames')
            .doc(normalizedUsername);
    final existingUsername =
        await usernameRef.get();
    if (existingUsername.exists) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
      );
    }
    // crea indice username
    await usernameRef.set({
      'uid': user.uid,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
    // crea profilo giocatore
    await _firestore
        .collection('viaggiatori')
        .doc(user.uid)
        .set({
      'username': username.trim(),
      'usernameLower': normalizedUsername,
      'email': user.email,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
  Future<void> updateEmail({
    required String email,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
      );
    }
    await _firestore
        .collection('viaggiatori')
        .doc(user.uid)
        .update({
      'email': email,
    });
  }
  Future<String?> getEmailFromUsername({
    required String username,
  }) async {
    final normalizedUsername =
        username.trim().toLowerCase();
    final snapshot = await _firestore
        .collection('viaggiatori')
        .where(
          'usernameLower',
          isEqualTo: normalizedUsername,
        )
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first
        .data()['email'] as String?;
  }
  Future<String?> getUsernameFromUid({
    required String uid,
  }) async {
    final snapshot =
        await _firestore
            .collection('viaggiatori')
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    return data?['username'] as String?;
  }
}