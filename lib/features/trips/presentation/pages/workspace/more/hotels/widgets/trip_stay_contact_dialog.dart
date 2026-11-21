// Pop-up "Contatta" di un alloggio: telefono (chiama, copia), email
// (scrivi, copia) e sito (apri, copia). Mostra solo i dati presenti; il
// pulsante che lo apre compare solo se ce n'è almeno uno.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_contact_row.dart';

/// True when the stay has at least a phone, an email or a website.
bool tripStayHasContacts(TripStay stay) =>
    stay.phone != null || stay.email != null || stay.propertyUrl != null;

Future<void> showTripStayContactDialog(
  BuildContext context,
  TripStay stay, {
  AmaterasuLaunch? launch,
}) {
  final open = launch ?? AmaterasuLinkOpener.defaultLaunch;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  void copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(l10n.staysContactCopied)));
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
          SnackBar(content: Text(l10n.staysContactOpenFailed)));
    }
  }

  final phone = stay.phone;
  final email = stay.email;
  final site = stay.propertyUrl;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('stay-contact-dialog'),
      backgroundColor: AmaterasuColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        l10n.staysContactTitle(stay.name),
        style: const TextStyle(color: AmaterasuColors.textPrimary,
            fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null)
              TripStayContactRow(
                id: 'phone',
                icon: Icons.phone_outlined,
                label: l10n.staysContactPhone,
                value: phone,
                actionLabel: l10n.staysContactCall,
                onAction: () => launchApp(Uri(scheme: 'tel',
                    path: phone.replaceAll(RegExp(r'[^0-9+]'), ''))),
                onCopy: () => copy(phone),
              ),
            if (email != null)
              TripStayContactRow(
                id: 'email',
                icon: Icons.mail_outline,
                label: l10n.staysContactEmail,
                value: email,
                actionLabel: l10n.staysContactWrite,
                onAction: () => launchApp(Uri(scheme: 'mailto', path: email)),
                onCopy: () => copy(email),
              ),
            if (site != null)
              TripStayContactRow(
                id: 'site',
                icon: Icons.language_rounded,
                label: l10n.staysContactWebsite,
                value: site,
                actionLabel: l10n.staysContactOpen,
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
          child: Text(l10n.staysContactClose),
        ),
      ],
    ),
  );
}
