// ignore_for_file: invalid_use_of_protected_member
part of 'login_card.dart';

extension _LoginCardStateLogin on _LoginCardState {
  Future<void> login() async {
    if (loading) return;
    setState(() {
      loading = true;
      loginError = null;
    });
    try {
      debugPrint("LOGIN: inizio");
      await RememberMeStorage.save(rememberMe);
      debugPrint("REMEMBER SALVATO: $rememberMe");
      final credential = await ref
          .read(authControllerProvider)
          .login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      final user = credential.user;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (kDebugMode) debugPrint("LOGIN OK: ${refreshedUser?.email}");
      if (!mounted) return;
      if (refreshedUser == null) {
        return;
      }
      if (!refreshedUser.emailVerified) {
        context.go(InviteAuthReturn.route('/verify-email', widget.returnTo));
      } else {
        context.go(InviteAuthReturn.destinationOrHome(widget.returnTo));
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("ERRORE LOGIN: ${e.code}");
      if (!mounted) return;
      setState(() {
        loginError = e.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getLoginErrorMessage(AppLocalizations l10n, String errorCode) {
    return switch (errorCode) {
      'user-not-found' => l10n.authLoginErrorUserNotFound,
      'wrong-password' => l10n.authLoginErrorWrongPassword,
      'invalid-email' => l10n.authLoginErrorInvalidEmail,
      _ => l10n.authLoginErrorGeneric,
    };
  }
}
