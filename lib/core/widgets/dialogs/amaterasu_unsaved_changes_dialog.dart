import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

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
          backgroundColor: const Color(0xFF1A1512),
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.unsavedChangesTitle,
            style: const TextStyle(
              color: Color(0xFFF2E7D5),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.unsavedChangesMessage,
            style: const TextStyle(color: Color(0xFF9E9287)),
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
                style: const TextStyle(color: Color(0xFFD66A5E)),
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
                style: const TextStyle(color: Color(0xFFE28A32)),
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
                style: const TextStyle(color: Color(0xFFF2E7D5)),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result ?? AmaterasuUnsavedChangesAction.cancel;
}
