import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

enum TripCoverSourceAction { camera, gallery, remove }

Future<TripCoverSourceAction?> showTripCoverSourceSheet({
  required BuildContext context,
  required bool hasCover,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<TripCoverSourceAction>(
    context: context,
    backgroundColor: const Color(0xFF1A1715),
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
                  color: Color(0xFFE86A3A),
                ),
                title: Text(
                  l10n.tripCoverCamera,
                  style: const TextStyle(color: Color(0xFFF2E7D5)),
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(TripCoverSourceAction.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFFE86A3A),
                ),
                title: Text(
                  l10n.tripCoverGallery,
                  style: const TextStyle(color: Color(0xFFF2E7D5)),
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(TripCoverSourceAction.gallery);
                },
              ),
              if (hasCover)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD66A5E),
                  ),
                  title: Text(
                    l10n.tripCoverRemove,
                    style: const TextStyle(color: Color(0xFFD66A5E)),
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
