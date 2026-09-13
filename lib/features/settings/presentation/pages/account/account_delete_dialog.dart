import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/settings/presentation/pages/account/account_delete_reauthentication.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/data/account_deletion_service.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountDeleteDialog extends ConsumerStatefulWidget {
  const AccountDeleteDialog({super.key});

  @override
  ConsumerState<AccountDeleteDialog> createState() =>
      _AccountDeleteDialogState();
}

class _AccountDeleteDialogState extends ConsumerState<AccountDeleteDialog> {
  bool _confirmed = false;
  bool _isDeleting = false;

  static const Color _backgroundColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFFB8AAA0);
  static const Color _dangerColor = Color(0xFFD35C4A);

  Future<void> _deleteAccount() async {
    if (!_confirmed || _isDeleting) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isDeleting = true;
    });

    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[ACCOUNT DELETE UI] DELETE FLOW START');
    debugPrint('==========================================');

    try {
      debugPrint('[ACCOUNT DELETE UI] Starting identity verification...');

      final reauthenticated =
          await AccountDeleteReauthentication.reauthenticate(
            context: context,
            ref: ref,
          );

      if (!reauthenticated) {
        debugPrint('[ACCOUNT DELETE UI] Reauthentication cancelled or failed.');
        debugPrint('[ACCOUNT DELETE UI] Account deletion NOT started.');
        debugPrint('==========================================');
        debugPrint('');

        return;
      }

      debugPrint('[ACCOUNT DELETE UI] Reauthentication successful.');

      if (!mounted) {
        debugPrint(
          '[ACCOUNT DELETE UI] Widget unmounted after reauthentication.',
        );
        return;
      }

      debugPrint('[ACCOUNT DELETE UI] Starting REAL account deletion...');

      await AccountDeletionService.deleteAccount();

      debugPrint('[ACCOUNT DELETE UI] Account deletion service completed.');

      if (!mounted) {
        debugPrint('[ACCOUNT DELETE UI] Widget unmounted after deletion.');
        return;
      }

      debugPrint('[ACCOUNT DELETE UI] Redirecting to login route "/".');

      debugPrint('==========================================');
      debugPrint('[ACCOUNT DELETE UI] DELETE FLOW COMPLETED');
      debugPrint('==========================================');
      debugPrint('');

      context.go('/');
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('[ACCOUNT DELETE UI] DELETE FLOW ERROR');
      debugPrint('[ACCOUNT DELETE UI] $error');
      debugPrint('[ACCOUNT DELETE UI] $stackTrace');
      debugPrint('==========================================');
      debugPrint('');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountDeleteError)));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderColor),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: _dangerColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.accountDeleteDialogTitle,
                style: const TextStyle(
                  color: _titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountDeleteDialogIntro,
                style: const TextStyle(
                  color: _titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.accountDeleteDialogData,
                style: const TextStyle(
                  color: _subtitleColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountDeleteDialogIrreversible,
                style: const TextStyle(
                  color: _subtitleColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: _isDeleting
                    ? null
                    : () {
                        setState(() {
                          _confirmed = !_confirmed;
                        });
                      },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _confirmed,
                        onChanged: _isDeleting
                            ? null
                            : (value) {
                                setState(() {
                                  _confirmed = value ?? false;
                                });
                              },
                        activeColor: _dangerColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n.accountDeleteDialogConfirmation,
                            style: const TextStyle(
                              color: _titleColor,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDeleting) ...[
                const SizedBox(height: 18),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: _dangerColor),
                      const SizedBox(height: 12),
                      Text(
                        l10n.accountDeleteLoading,
                        style: const TextStyle(
                          color: _subtitleColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text(l10n.accountDeleteCancel),
          ),
          FilledButton(
            onPressed: _confirmed && !_isDeleting ? _deleteAccount : null,
            style: FilledButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _dangerColor.withValues(alpha: 0.25),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
            ),
            child: Text(l10n.accountDeleteConfirmButton),
          ),
        ],
      ),
    );
  }
}
