// Pop-up "Contatta" di un luogo (alloggi e altre sezioni): telefono
// (chiama, copia), email (scrivi, copia) e sito (apri, copia). Mostra solo i dati presenti; il
// pulsante che lo apre compare solo se ce n'è almeno uno.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_contact_row.dart';

/// True when there is at least a phone, an email or a website.
bool amaterasuHasContacts({String? phone, String? email, String? website}) =>
    phone != null || email != null || website != null;

Future<void> showAmaterasuContactDialog(
  BuildContext context, {
  required String title,
  String? phone,
  String? email,
  String? website,
  AmaterasuLaunch? launch,
  String keyPrefix = 'place-contact',
}) {
  final open = launch ?? AmaterasuLinkOpener.defaultLaunch;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  void copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(l10n.placesContactCopied)));
  }

  Future<void> launchApp(Uri uri) async {
    var opened = false;
    try {
      opened = await open(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.placesContactOpenFailed)),
      );
    }
  }

  final site = website;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: Key('$keyPrefix-dialog'),
      backgroundColor: AmaterasuColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: const TextStyle(
          color: AmaterasuColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null)
              AmaterasuContactRow(
                keyPrefix: keyPrefix,
                id: 'phone',
                icon: Icons.phone_outlined,
                label: l10n.placesContactPhone,
                value: phone,
                actionLabel: l10n.placesContactCall,
                onAction: () => launchApp(
                  Uri(
                    scheme: 'tel',
                    path: phone.replaceAll(RegExp(r'[^0-9+]'), ''),
                  ),
                ),
                onCopy: () => copy(phone),
              ),
            if (email != null)
              AmaterasuContactRow(
                keyPrefix: keyPrefix,
                id: 'email',
                icon: Icons.mail_outline,
                label: l10n.placesContactEmail,
                value: email,
                actionLabel: l10n.placesContactWrite,
                onAction: () => launchApp(Uri(scheme: 'mailto', path: email)),
                onCopy: () => copy(email),
              ),
            if (site != null)
              AmaterasuContactRow(
                keyPrefix: keyPrefix,
                id: 'site',
                icon: Icons.language_rounded,
                label: l10n.placesContactWebsite,
                value: site,
                actionLabel: l10n.placesContactOpen,
                onAction: () => AmaterasuLinkOpener.openWebLink(
                  context,
                  site,
                  invalidMessage: l10n.commonLinkInvalid,
                  failedMessage: l10n.commonLinkOpenFailed,
                  copyLabel: l10n.commonLinkCopy,
                  launch: open,
                ),
                onCopy: () => copy(site),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.placesContactClose),
        ),
      ],
    ),
  );
}
