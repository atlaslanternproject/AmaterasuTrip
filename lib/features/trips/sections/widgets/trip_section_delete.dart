// Eliminazione di un elemento di una sezione con doppia conferma nel
// pannello condiviso (rosso, "vale per tutti") e messaggio con l'esito.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_confirm.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> confirmTripSectionDelete(
  BuildContext context, {
  required String keyPrefix,
  required String name,
  required Future<void> Function() delete,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await confirmAmaterasuAction(
    context,
    title: l10n.sectionsDeleteTitle,
    body: l10n.sectionsDeleteBody(name),
    confirmLabel: l10n.sectionsDelete,
    destructive: true,
    icon: Icons.delete_outline_rounded,
    keyPrefix: '$keyPrefix-delete',
  );
  if (!confirmed) return;
  try {
    await delete();
    messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsDeleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsDeleteError)));
  }
}
