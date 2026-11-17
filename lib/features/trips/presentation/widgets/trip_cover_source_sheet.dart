// Foglio in basso per scegliere la copertina (galleria, fotocamera, rimozione).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

enum TripCoverSourceAction { camera, gallery, remove }

Future<TripCoverSourceAction?> showTripCoverSourceSheet({
  required BuildContext context,
  required bool hasCover,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<TripCoverSourceAction>(
    context: context,
    backgroundColor: AmaterasuColors.surfaceNeutral,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AmaterasuColors.accentFlame,
                ),
                title: Text(
                  l10n.tripCoverCamera,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop(TripCoverSourceAction.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AmaterasuColors.accentFlame,
                ),
                title: Text(
                  l10n.tripCoverGallery,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop(TripCoverSourceAction.gallery);
                },
              ),
              if (hasCover)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AmaterasuColors.accentRose,
                  ),
                  title: Text(
                    l10n.tripCoverRemove,
                    style: const TextStyle(color: AmaterasuColors.accentRose),
                  ),
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop(TripCoverSourceAction.remove);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
