// Eliminazione di un elemento di una sezione con conferma: spiega che vale
// per tutti i viaggiatori e mostra l'esito con un messaggio.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> confirmTripSectionDelete(
  BuildContext context, {
  required String keyPrefix,
  required String name,
  required Future<void> Function() delete,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.sectionsDeleteTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: Text(
        l10n.sectionsDeleteBody(name),
        style: const TextStyle(color: AmaterasuColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.sectionsCancel),
        ),
        FilledButton(
          key: Key('$keyPrefix-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: AmaterasuColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.sectionsDelete),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await delete();
    messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsDeleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsDeleteError)));
  }
}
