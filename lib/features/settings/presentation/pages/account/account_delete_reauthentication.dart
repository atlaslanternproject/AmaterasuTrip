import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountDeleteReauthentication {
  const AccountDeleteReauthentication._();

  static Future<bool> reauthenticate({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final user = ref.read(authControllerProvider).currentUser;

    if (user == null) {
      return false;
    }

    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .toList();

    try {
      if (providerIds.contains('password')) {
        final password = await _requestPassword(context);

        if (password == null || password.isEmpty) {
          return false;
        }

        await ref
            .read(authControllerProvider)
            .reauthenticateWithPassword(password: password);

        return true;
      }

      if (providerIds.contains('google.com')) {
        await ref.read(authControllerProvider).reauthenticateWithGoogle();

        return true;
      }

      if (context.mounted) {
        _showError(
          context,
          AppLocalizations.of(
            context,
          )!.accountDeleteReauthenticationUnsupported,
        );
      }

      return false;
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) {
        return false;
      }

      final l10n = AppLocalizations.of(context)!;

      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        _showError(context, l10n.accountDeleteReauthenticationWrongPassword);
      } else if (error.code == 'google-sign-in-cancelled') {
        _showError(context, l10n.accountDeleteReauthenticationCancelled);
      } else if (error.code == 'user-mismatch') {
        _showError(context, l10n.accountDeleteReauthenticationGoogleMismatch);
      } else {
        _showError(context, l10n.accountDeleteReauthenticationFailed);
      }

      return false;
    } catch (_) {
      if (context.mounted) {
        _showError(
          context,
          AppLocalizations.of(context)!.accountDeleteReauthenticationFailed,
        );
      }

      return false;
    }
  }

  static Future<String?> _requestPassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    String password = '';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountDeleteReauthenticationTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.accountDeleteReauthenticationPasswordDescription),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.accountDeleteReauthenticationPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onChanged: (value) {
                  password = value;
                },
                onSubmitted: (value) {
                  final normalizedPassword = value.trim();

                  if (normalizedPassword.isNotEmpty) {
                    Navigator.of(dialogContext).pop(normalizedPassword);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.accountDeleteCancel),
            ),
            FilledButton(
              onPressed: () {
                final normalizedPassword = password.trim();

                if (normalizedPassword.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(normalizedPassword);
              },
              child: Text(l10n.accountDeleteReauthenticationConfirm),
            ),
          ],
        );
      },
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
