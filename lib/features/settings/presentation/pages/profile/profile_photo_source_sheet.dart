// Foglio in basso per scegliere la foto del profilo
// (galleria, fotocamera o rimozione).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

enum ProfilePhotoSourceAction { camera, gallery, remove }

Future<ProfilePhotoSourceAction?> showProfilePhotoSourceSheet({
  required BuildContext context,
  required bool hasCustomPhoto,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<ProfilePhotoSourceAction>(
    context: context,
    backgroundColor: AmaterasuColors.surface,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AmaterasuColors.accentSettings,
                ),
                title: Text(
                  l10n.profilePhotoCamera,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(ProfilePhotoSourceAction.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AmaterasuColors.accentSettings,
                ),
                title: Text(
                  l10n.profilePhotoGallery,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(ProfilePhotoSourceAction.gallery);
                },
              ),
              if (hasCustomPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AmaterasuColors.accentRose,
                  ),
                  title: Text(
                    l10n.profilePhotoRemove,
                    style: const TextStyle(color: AmaterasuColors.accentRose),
                  ),
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop(ProfilePhotoSourceAction.remove);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
