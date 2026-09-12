part of 'account_email_page.dart';

mixin _AccountEmailActions on ConsumerState<AccountEmailPage> {
  bool _loading = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authControllerProvider).currentUser;

    _verified = user?.emailVerified ?? false;
  }

  Future<void> _refreshVerificationStatus() async {
    if (_loading) return;

    final controller = ref.read(authControllerProvider);

    setState(() {
      _loading = true;
    });

    try {
      await controller.reloadCurrentUser();

      if (!mounted) return;

      setState(() {
        _verified = controller.currentUser?.emailVerified ?? false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _loading = true;
    });

    try {
      await ref.read(authControllerProvider).resendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.accountEmailVerificationSent)),
        );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_firebaseErrorMessage(error, l10n))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showChangeEmailDialog() async {
    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ChangeEmailWarningDialog(l10n: l10n),
    );

    if (!mounted || confirmed != true) return;

    final result = await showDialog<_ChangeEmailResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ChangeEmailDialog(l10n: l10n),
    );

    if (!mounted || result == null) return;

    if (result.password.isEmpty || result.newEmail.isEmpty) {
      return;
    }

    await _changeEmail(password: result.password, newEmail: result.newEmail);
  }

  Future<void> _changeEmail({
    required String password,
    required String newEmail,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _loading = true;
    });

    try {
      await ref
          .read(authControllerProvider)
          .changeEmail(currentPassword: password, newEmail: newEmail);

      if (!mounted) return;

      await _showEmailVerificationDialog();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_firebaseErrorMessage(error, l10n))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangeEmailVerificationDialog(
        l10n: l10n,
        onVerified: _checkNewEmailVerification,
        onResend: _resendChangeEmailVerification,
      ),
    );
  }

  Future<void> _checkNewEmailVerification() async {
    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(authControllerProvider);

    setState(() {
      _loading = true;
    });

    try {
      await controller.reloadCurrentUser();

      final user = controller.currentUser;

      if (user?.emailVerified ?? false) {
        if (!mounted) return;

        Navigator.of(context).pop();

        await controller.logout();

        if (!mounted) return;

        context.go('/');

        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.authVerifyEmailNotVerified)),
        );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_firebaseErrorMessage(error, l10n))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendChangeEmailVerification() async {
    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _loading = true;
    });

    try {
      await ref.read(authControllerProvider).resendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.authVerifyEmailSent)));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_firebaseErrorMessage(error, l10n))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _firebaseErrorMessage(
    FirebaseAuthException error,
    AppLocalizations l10n,
  ) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.accountEmailErrorInvalidPassword;

      case 'email-already-in-use':
        return l10n.accountEmailErrorAlreadyInUse;

      case 'invalid-email':
        return l10n.accountEmailErrorInvalidEmail;

      case 'requires-recent-login':
        return l10n.accountEmailErrorRecentLogin;

      case 'too-many-requests':
        return l10n.accountEmailErrorTooManyRequests;

      case 'user-not-found':
        return l10n.accountEmailErrorUserNotFound;

      default:
        return l10n.accountEmailErrorGeneric;
    }
  }
}
