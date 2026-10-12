import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<XFile?> showWebMediaConsentDialog({
  required BuildContext context,
  required bool fromCamera,
  required Future<XFile?> Function() pickImage,
  required String errorMessage,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<XFile?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      bool isPicking = false;
      bool hasError = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              fromCamera ? l10n.webMediaCameraTitle : l10n.webMediaGalleryTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromCamera
                      ? l10n.webMediaCameraBody
                      : l10n.webMediaGalleryBody,
                ),
                if (hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isPicking
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: isPicking
                    ? null
                    : () {
                        setDialogState(() {
                          isPicking = true;
                          hasError = false;
                        });

                        // Il picker parte direttamente dal clic dell'utente.
                        // Nessun await prima dell'apertura del browser picker.
                        Future<XFile?> selection;

                        try {
                          selection = pickImage();
                        } catch (_) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              isPicking = false;
                              hasError = true;
                            });
                          }
                          return;
                        }

                        selection.then(
                          (file) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(file);
                            }
                          },
                          onError: (Object error, StackTrace stackTrace) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isPicking = false;
                                hasError = true;
                              });
                            }
                          },
                        );
                      },
                child: Text(l10n.webMediaContinue),
              ),
            ],
          );
        },
      );
    },
  );
}
