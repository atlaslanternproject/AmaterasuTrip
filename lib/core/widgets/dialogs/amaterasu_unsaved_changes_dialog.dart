import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

enum AmaterasuUnsavedChangesAction { discard, saveAndExit, cancel }

Future<AmaterasuUnsavedChangesAction> showAmaterasuUnsavedChangesDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;

  final result = await showDialog<AmaterasuUnsavedChangesAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AmaterasuColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.unsavedChangesTitle,
            style: const TextStyle(
              color: AmaterasuColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.unsavedChangesMessage,
            style: const TextStyle(color: AmaterasuColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(AmaterasuUnsavedChangesAction.discard);
              },
              child: Text(
                l10n.unsavedChangesDiscard,
                style: const TextStyle(color: AmaterasuColors.accentRose),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(AmaterasuUnsavedChangesAction.saveAndExit);
              },
              child: Text(
                l10n.unsavedChangesSaveAndExit,
                style: const TextStyle(color: AmaterasuColors.accentSettings),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(AmaterasuUnsavedChangesAction.cancel);
              },
              child: Text(
                l10n.unsavedChangesCancel,
                style: const TextStyle(color: AmaterasuColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result ?? AmaterasuUnsavedChangesAction.cancel;
}
