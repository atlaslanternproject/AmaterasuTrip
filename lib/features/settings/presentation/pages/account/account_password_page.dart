import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/buttons/Amaterasu_primary_button.dart';
import 'package:amaterasutrip/core/widgets/inputs/amaterasu_password_field.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountPasswordPage extends StatefulWidget {
  const AccountPasswordPage({super.key});

  @override
  State<AccountPasswordPage> createState() => _AccountPasswordPageState();
}

class _AccountPasswordPageState extends State<AccountPasswordPage> {
  bool _loading = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _hasPasswordProvider {
    final user = _user;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  Future<void> _showChangePasswordDialog() async {
    if (_loading || !_hasPasswordProvider) {
      return;
    }

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const _ChangePasswordDialog();
      },
    );

    if (!mounted || changed != true) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    _showMessage(l10n.accountPasswordChanged);
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_loading || !_hasPasswordProvider) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final email = _user?.email;

    if (email == null || email.isEmpty) {
      _showMessage(l10n.accountPasswordErrorNoEmail);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountPasswordRecover),
          content: Text(l10n.accountPasswordRecoverDescription(email)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.accountPasswordSendReset),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) {
        return;
      }

      _showMessage(l10n.accountPasswordResetSent);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_passwordErrorMessage(error, l10n));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasPasswordProvider) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF211A16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A2A20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_circle_outlined, color: Color(0xFFE28A32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.accountPasswordManagedByProvider,
                style: const TextStyle(
                  color: Color(0xFFD6C8B8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _PasswordSubItem(
          icon: Icons.password_outlined,
          title: l10n.accountPasswordChange,
          subtitle: l10n.accountPasswordChangeDescription,
          onTap: _loading ? null : _showChangePasswordDialog,
        ),
        const SizedBox(height: 8),
        _PasswordSubItem(
          icon: Icons.mark_email_read_outlined,
          title: l10n.accountPasswordRecover,
          subtitle: l10n.accountPasswordRecoverSubtitle,
          onTap: _loading ? null : _sendPasswordResetEmail,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final currentPassword = _currentPasswordController.text;

    final newPassword = _newPasswordController.text;

    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(l10n.accountPasswordErrorEmptyFields);
      return;
    }

    if (newPassword.length < 6) {
      _showMessage(l10n.accountPasswordErrorWeak);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage(l10n.accountPasswordErrorMismatch);
      return;
    }

    if (currentPassword == newPassword) {
      _showMessage(l10n.accountPasswordErrorSamePassword);
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final email = user?.email;

      if (user == null || email == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_passwordErrorMessage(error, l10n));

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(l10n.accountPasswordErrorGeneric);

      setState(() {
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.accountPasswordChange),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmaterasuPasswordField(
              controller: _currentPasswordController,
              hintText: l10n.accountPasswordCurrent,
            ),
            const SizedBox(height: 12),
            AmaterasuPasswordField(
              controller: _newPasswordController,
              hintText: l10n.accountPasswordNew,
            ),
            const SizedBox(height: 12),
            AmaterasuPasswordField(
              controller: _confirmPasswordController,
              hintText: l10n.accountPasswordConfirmNew,
            ),
            const SizedBox(height: 20),
            AmaterasuPrimaryButton(
              text: _loading
                  ? l10n.accountPasswordChanging
                  : l10n.accountPasswordConfirmChange,
              onPressed: _loading ? null : _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

String _passwordErrorMessage(
  FirebaseAuthException error,
  AppLocalizations l10n,
) {
  switch (error.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return l10n.accountPasswordErrorWrongCurrent;

    case 'weak-password':
      return l10n.accountPasswordErrorWeak;

    case 'requires-recent-login':
      return l10n.accountPasswordErrorRecentLogin;

    case 'too-many-requests':
      return l10n.accountPasswordErrorTooManyRequests;

    case 'user-not-found':
      return l10n.accountPasswordErrorUserNotFound;

    default:
      return l10n.accountPasswordErrorGeneric;
  }
}

class _PasswordSubItem extends StatelessWidget {
  const _PasswordSubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _chevronColor = Color(0xFFB89B7A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: _sectionColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.65),
                  ),
                ),
                child: Icon(icon, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              const Icon(Icons.chevron_right, color: _chevronColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
