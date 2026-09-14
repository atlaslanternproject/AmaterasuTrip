import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

enum ProfilePhotoSourceAction { camera, gallery, remove }

Future<ProfilePhotoSourceAction?> showProfilePhotoSourceSheet({
  required BuildContext context,
  required bool hasCustomPhoto,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<ProfilePhotoSourceAction>(
    context: context,
    backgroundColor: const Color(0xFF1A1512),
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
                  color: Color(0xFFE28A32),
                ),
                title: Text(
                  l10n.profilePhotoCamera,
                  style: const TextStyle(color: Color(0xFFF2E7D5)),
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
                  color: Color(0xFFE28A32),
                ),
                title: Text(
                  l10n.profilePhotoGallery,
                  style: const TextStyle(color: Color(0xFFF2E7D5)),
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
                    color: Color(0xFFD66A5E),
                  ),
                  title: Text(
                    l10n.profilePhotoRemove,
                    style: const TextStyle(color: Color(0xFFD66A5E)),
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
