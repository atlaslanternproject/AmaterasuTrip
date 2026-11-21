// Eliminazione di un soggiorno con conferma: spiega che "annullato" è uno
// stato e che l'eliminazione vale per tutti; mostra l'esito.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/data/trip_stays_repository.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> confirmAndDeleteTripStay(
  BuildContext context,
  TripStaysRepository repository,
  TripStay stay,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      title: Text(
        l10n.staysDeleteTitle,
        style: const TextStyle(color: AmaterasuColors.textPrimary),
      ),
      content: Text(
        l10n.staysDeleteBody(stay.name),
        style: const TextStyle(color: AmaterasuColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.staysCancel),
        ),
        FilledButton(
          key: const Key('stay-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: AmaterasuColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.staysDelete),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await repository.delete(tripId: stay.tripId, stayId: stay.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.staysDeleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.staysDeleteError)));
  }
}
