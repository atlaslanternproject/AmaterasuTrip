import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createUsername({required String username}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Nessun utente autenticato');
    }

    final normalizedUsername = username.trim().toLowerCase();

    if (normalizedUsername.isEmpty) {
      throw Exception('Username non può essere vuoto');
    }

    final usernameRef = _firestore
        .collection('usernames')
        .doc(normalizedUsername);

    final existingUsername = await usernameRef.get();

    if (existingUsername.exists) {
      throw FirebaseAuthException(code: 'username-already-in-use');
    }

    await usernameRef.set({
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('viaggiatori').doc(user.uid).set({
      'username': username.trim(),
      'usernameLower': normalizedUsername,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserProfile?> watchCurrentUserProfile() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('viaggiatori').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return UserProfile.fromFirestore(uid: snapshot.id, data: data);
    });
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    final trimmedBio = bio.trim();

    await _firestore.collection('viaggiatori').doc(user.uid).update({
      'firstName': trimmedFirstName.isEmpty
          ? FieldValue.delete()
          : trimmedFirstName,
      'lastName': trimmedLastName.isEmpty
          ? FieldValue.delete()
          : trimmedLastName,
      'bio': trimmedBio.isEmpty ? FieldValue.delete() : trimmedBio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUsername({required String username}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final trimmedUsername = username.trim();
    final normalizedUsername = trimmedUsername.toLowerCase();

    if (normalizedUsername.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-username');
    }

    final profileRef = _firestore.collection('viaggiatori').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileRef);

      if (!profileSnapshot.exists) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      final profileData = profileSnapshot.data();

      if (profileData == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      final currentUsername = profileData['username'] as String? ?? '';

      final currentNormalizedUsername =
          profileData['usernameLower'] as String? ??
          currentUsername.trim().toLowerCase();

      if (normalizedUsername == currentNormalizedUsername) {
        transaction.update(profileRef, {
          'username': trimmedUsername,
          'usernameLower': normalizedUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return;
      }

      final newUsernameRef = _firestore
          .collection('usernames')
          .doc(normalizedUsername);

      final newUsernameSnapshot = await transaction.get(newUsernameRef);

      if (newUsernameSnapshot.exists) {
        final existingData = newUsernameSnapshot.data();
        final existingUid = existingData?['uid'] as String?;

        if (existingUid != user.uid) {
          throw FirebaseAuthException(code: 'username-already-in-use');
        }
      }

      if (!newUsernameSnapshot.exists) {
        transaction.set(newUsernameRef, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (currentNormalizedUsername.isNotEmpty) {
        final oldUsernameRef = _firestore
            .collection('usernames')
            .doc(currentNormalizedUsername);

        transaction.delete(oldUsernameRef);
      }

      transaction.update(profileRef, {
        'username': trimmedUsername,
        'usernameLower': normalizedUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateEmail({required String email}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    await _firestore.collection('viaggiatori').doc(user.uid).update({
      'email': email,
    });
  }

  Future<String?> getEmailFromUsername({required String username}) async {
    final normalizedUsername = username.trim().toLowerCase();

    final snapshot = await _firestore
        .collection('viaggiatori')
        .where('usernameLower', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data()['email'] as String?;
  }

  Future<String?> getUsernameFromUid({required String uid}) async {
    final snapshot = await _firestore.collection('viaggiatori').doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    return data?['username'] as String?;
  }

  Future<void> updateProfilePhoto({
    required String photoUrl,
    required String photoPath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _firestore.collection('viaggiatori').doc(user.uid).update({
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _firestore.collection('viaggiatori').doc(user.uid).update({
      'photoUrl': FieldValue.delete(),
      'photoPath': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
