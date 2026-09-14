import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/providers/auth_controller.dart';
import '../../../../../l10n/app_localizations.dart';

class AccountLogoutPage extends ConsumerWidget {
  const AccountLogoutPage({super.key});
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).logout();
    if (!context.mounted) return;
    context.go('/');
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.logout, color: colorScheme.error, size: 36),
          title: Text(l10n.accountLogoutTitle, textAlign: TextAlign.center),
          content: Text(
            l10n.accountLogoutDescription,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.accountLogoutStay),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _logout(context, ref);
              },
              child: Text(l10n.accountLogoutConfirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.logout, color: colorScheme.error),
      title: Text(
        l10n.accountLogout,
        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        _showLogoutDialog(context, ref);
      },
    );
  }
}
