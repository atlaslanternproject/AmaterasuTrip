// Email di assistenza (Impostazioni > Assistenza), unico flusso per
// contattarci: "Contatti" apre un'email vuota, "Segnala un problema" e
// "Suggerisci un'idea" la aprono già compilata (oggetto, versione, build e
// lingua dell'app). Nessun dato salvato su Firebase: l'email parte
// dall'app di posta dell'utente.

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

enum AmaterasuSupportKind { bug, idea }

abstract final class AmaterasuSupportEmail {
  static const address = 'atlaslanternproject@gmail.com';

  /// An email to [address], with [subject] and [body] when given.
  static Uri uri({String? subject, String? body}) {
    final query = [
      if (subject != null) 'subject=${Uri.encodeComponent(subject)}',
      if (body != null) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return Uri(
      scheme: 'mailto',
      path: address,
      query: query.isEmpty ? null : query,
    );
  }

  /// Opens the mail app with an empty email to the support address.
  static Future<void> contact() async {
    await launchUrl(uri());
  }

  /// The prepared email of a report or an idea.
  static Uri reportUri(
    AppLocalizations l10n,
    AmaterasuSupportKind kind, {
    required String version,
    required String build,
    required String language,
  }) => uri(
    subject: kind == AmaterasuSupportKind.bug
        ? l10n.supportEmailBugSubject
        : l10n.supportEmailIdeaSubject,
    body: kind == AmaterasuSupportKind.bug
        ? l10n.supportEmailBugBody(version, build, language)
        : l10n.supportEmailIdeaBody(version, build, language),
  );

  /// Opens the mail app with the prepared email of [kind].
  static Future<void> report(
    BuildContext context,
    AmaterasuSupportKind kind,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final info = await PackageInfo.fromPlatform();
    await launchUrl(
      reportUri(
        l10n,
        kind,
        version: info.version,
        build: info.buildNumber,
        language: language,
      ),
    );
  }
}
