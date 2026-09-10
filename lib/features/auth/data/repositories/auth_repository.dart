import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  AuthRepository(this._firebaseAuth);
  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();
  User? get currentUser =>
      _firebaseAuth.currentUser;
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    // Forza sempre la scelta account Google
    // (utile anche se un account Ã¨ giÃ  loggato)
    await googleSignIn.signOut();
    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();
    // Utente chiude il popup
    if (googleUser == null) {
      return null;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential =
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
    return await _firebaseAuth.signInWithCredential(
      credential,
    );
  }
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }
}
