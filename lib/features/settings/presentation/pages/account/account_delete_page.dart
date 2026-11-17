// Sezione dell'account per avviare la cancellazione dell'account.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/account/account_delete_dialog.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class AccountDeletePage extends StatelessWidget {
  const AccountDeletePage({super.key});

  static const Color _dangerColor = Color(0xFFD35C4A);
  static const Color _textColor = AmaterasuColors.textPrimary;
  static const Color _subtitleColor = AmaterasuColors.textMuted;
  static const Color _backgroundColor = AmaterasuColors.surface;
  static const Color _borderColor = AmaterasuColors.borderWarm;

  Future<void> _showDeleteDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AccountDeleteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AmaterasuSpacing.md),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountDeleteIntro,
            style: const TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.accountDeleteWarning,
            style: const TextStyle(
              color: _subtitleColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AmaterasuSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteDialog(context),
              icon: const Icon(Icons.delete_forever_outlined, size: 20),
              label: Text(l10n.accountDeleteButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dangerColor,
                side: const BorderSide(color: _dangerColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
