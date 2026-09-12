import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_provider.dart';
import 'package:amaterasutrip/features/profile/data/repositories/user_repository.dart';
import 'package:amaterasutrip/features/profile/providers/user_provider.dart';
final authControllerProvider =
    Provider<AuthController>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthController(
    repository,
    userRepository,
  );
});
class AuthController {
  final AuthRepository _repository;
  final UserRepository _userRepository;
  AuthController(
    this._repository,
    this._userRepository,
  );
  User? get currentUser =>
      _repository.currentUser;
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
  Future<UserCredential> loginWithEmailorUsername({
    required String identifier,
    required String password,
  }) async {
    String email = identifier.trim();
    if (!email.contains('@')) {
      final foundEmail =
          await _userRepository.getEmailFromUsername(
        username: email,
      );
      if (foundEmail == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
        );
      }
      email = foundEmail;
    }
    return await _repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
  Future<UserCredential?> loginWithGoogle() async {
    return await _repository.signInWithGoogle();
  }
  Future<UserCredential> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final credential =
        await _repository.registerWithEmail(
      email: email,
      password: password,
    );
    await _userRepository.createUsername(username: username);
    await credential.user?.sendEmailVerification();
    return credential;
  }
  Future<void> resendEmailVerification() async {
    await _repository.sendEmailVerification();
  }
  Future<void> reloadCurrentUser() async {
    await _repository.reloadCurrentUser();
  }
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    await _repository.reauthenticateWithPassword(
      password: currentPassword,
    );
    await _repository.verifyBeforeUpdateEmail(
      newEmail: newEmail,
    );
  }
  Future<void> logout() async {
    await _repository.signOut();
  }
}