// Chip di un link, con lo stesso aspetto della bucket list: icona
// "apri" piccola e nome del sito (o un testo dato). Al tocco apre il link
// con AmaterasuLinkOpener e i messaggi di lib/l10n.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_link_opener.dart';
import 'amaterasu_web_link.dart';

class AmaterasuLinkChip extends StatelessWidget {
  const AmaterasuLinkChip({
    super.key,
    required this.link,
    this.label,
    this.launch,
  });

  final String link;

  /// Text on the chip; when null, the site name of the link.
  final String? label;

  /// Replaces url_launcher in tests.
  final AmaterasuLaunch? launch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = label ?? AmaterasuWebLink.label(link, l10n.commonLinkOpen);

    return ActionChip(
      avatar: const Icon(Icons.open_in_new, size: 15),
      label: Text(text, overflow: TextOverflow.ellipsis),
      onPressed: () => AmaterasuLinkOpener.openWebLink(
        context,
        link,
        invalidMessage: l10n.commonLinkInvalid,
        failedMessage: l10n.commonLinkOpenFailed,
        copyLabel: l10n.commonLinkCopy,
        launch: launch ?? AmaterasuLinkOpener.defaultLaunch,
      ),
    );
  }
}
