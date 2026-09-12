part of 'account_email_page.dart';

class _ChangeEmailWarningDialog extends StatelessWidget {
  const _ChangeEmailWarningDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.accountEmailChange),
      content: Text(l10n.accountEmailChangeLogoutWarning),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.accountEmailChangeContinue),
        ),
      ],
    );
  }
}

class _ChangeEmailVerificationDialog extends StatelessWidget {
  const _ChangeEmailVerificationDialog({
    required this.l10n,
    required this.onVerified,
    required this.onResend,
  });

  final AppLocalizations l10n;
  final VoidCallback onVerified;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.authVerifyEmailTitle),
      content: Text(l10n.authVerifyEmailDescription),
      actions: [
        TextButton(
          onPressed: onResend,
          child: Text(l10n.authVerifyEmailResend),
        ),
        FilledButton(
          onPressed: onVerified,
          child: Text(l10n.authVerifyEmailConfirmed),
        ),
      ],
    );
  }
}

class _ChangeEmailResult {
  const _ChangeEmailResult({required this.password, required this.newEmail});

  final String password;
  final String newEmail;
}

class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  late final TextEditingController _passwordController;

  late final TextEditingController _emailController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _passwordController = TextEditingController();

    _emailController = TextEditingController();
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
      title: Text(l10n.accountEmailChange),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.accountEmailCurrentPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(labelText: l10n.accountEmailNew),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ChangeEmailResult(
                password: _passwordController.text.trim(),
                newEmail: _emailController.text.trim(),
              ),
            );
          },
          child: Text(l10n.accountEmailConfirmChange),
        ),
      ],
    );
  }
}
