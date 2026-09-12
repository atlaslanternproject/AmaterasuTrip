import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
class AccountEmailPage extends ConsumerStatefulWidget {
  const AccountEmailPage({super.key});
  @override
  ConsumerState<AccountEmailPage> createState() =>
      _AccountEmailPageState();
}
class _AccountEmailPageState
    extends ConsumerState<AccountEmailPage> {
  bool _loading = false;
  bool _verified = false;
  @override
  void initState() {
    super.initState();
    final user =
        ref.read(authControllerProvider).currentUser;
    _verified = user?.emailVerified ?? false;
  }
  Future<void> _refreshVerificationStatus() async {
    if (_loading) return;
    final controller =
        ref.read(authControllerProvider);
    setState(() {
      _loading = true;
    });
    try {
      await controller.reloadCurrentUser();
      if (!mounted) return;
      setState(() {
        _verified =
            controller.currentUser?.emailVerified ?? false;
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
      await ref
          .read(authControllerProvider)
          .resendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountEmailVerificationSent,
            ),
          ),
        );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _firebaseErrorMessage(error, l10n),
            ),
          ),
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
    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ChangeEmailWarningDialog(
        l10n: l10n,
      ),
    );
    if (!mounted || confirmed != true) return;
    final result =
        await showDialog<_ChangeEmailResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ChangeEmailDialog(
        l10n: l10n,
      ),
    );
    if (!mounted || result == null) return;
    if (result.password.isEmpty ||
        result.newEmail.isEmpty) {
      return;
    }
    await _changeEmail(
      password: result.password,
      newEmail: result.newEmail,
    );
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
          .changeEmail(
            currentPassword: password,
            newEmail: newEmail,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountEmailChangeVerificationSent,
            ),
          ),
        );
      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );
      if (!mounted) return;
      await ref
          .read(authControllerProvider)
          .logout();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _firebaseErrorMessage(error, l10n),
            ),
          ),
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user =
        ref.watch(authControllerProvider).currentUser;
    final email =
        user?.email ?? l10n.accountEmailUnavailable;
    return Column(
      children: [
        _AccountSubItem(
          icon: Icons.alternate_email,
          title: l10n.accountEmailCurrent,
          subtitle: email,
          onTap: () {},
        ),
        _AccountSubItem(
          icon: _verified
              ? Icons.verified_outlined
              : Icons.mark_email_unread_outlined,
          title: _verified
              ? l10n.accountEmailVerified
              : l10n.accountEmailNotVerified,
          subtitle: _verified
              ? l10n.accountEmailVerifiedDescription
              : l10n.accountEmailVerify,
          onTap: _verified
              ? _refreshVerificationStatus
              : _resendVerificationEmail,
        ),
        _AccountSubItem(
          icon: Icons.edit_outlined,
          title: l10n.accountEmailChange,
          subtitle:
              l10n.accountEmailChangeDescription,
          onTap: _showChangeEmailDialog,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}
class _ChangeEmailWarningDialog extends StatelessWidget {
  const _ChangeEmailWarningDialog({
    required this.l10n,
  });
  final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        l10n.accountEmailChange,
      ),
      content: Text(
        l10n.accountEmailChangeLogoutWarning,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            l10n.cancel,
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(
            l10n.accountEmailChangeContinue,
          ),
        ),
      ],
    );
  }
}
class _ChangeEmailResult {
  const _ChangeEmailResult({
    required this.password,
    required this.newEmail,
  });
  final String password;
  final String newEmail;
}
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({
    required this.l10n,
  });
  final AppLocalizations l10n;
  @override
  State<_ChangeEmailDialog> createState() =>
      _ChangeEmailDialogState();
}
class _ChangeEmailDialogState
    extends State<_ChangeEmailDialog> {
  late final TextEditingController
      _passwordController;
  late final TextEditingController
      _emailController;
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    _passwordController =
        TextEditingController();
    _emailController =
        TextEditingController();
  }
  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(
        l10n.accountEmailChange,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            textInputAction:
                TextInputAction.next,
            decoration: InputDecoration(
              labelText:
                  l10n.accountEmailCurrentPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(
              labelText:
                  l10n.accountEmailNew,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            l10n.cancel,
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ChangeEmailResult(
                password:
                    _passwordController.text.trim(),
                newEmail:
                    _emailController.text.trim(),
              ),
            );
          },
          child: Text(
            l10n.accountEmailConfirmChange,
          ),
        ),
      ],
    );
  }
}
class _AccountSubItem extends StatelessWidget {
  const _AccountSubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  static const Color _sectionColor =
      Color(0xFF1A1512);
  static const Color _borderColor =
      Color(0xFF3A2A20);
  static const Color _accentColor =
      Color(0xFFE28A32);
  static const Color _titleColor =
      Color(0xFFF2E7D5);
  static const Color _subtitleColor =
      Color(0xFF9E9287);
  static const Color _chevronColor =
      Color(0xFFB89B7A);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: _sectionColor,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        _accentColor.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _subtitleColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: _chevronColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}