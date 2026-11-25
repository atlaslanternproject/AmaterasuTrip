// "Cosa c'è di nuovo": dopo un aggiornamento mostra UNA volta sola le
// novità della versione installata, nella lingua dell'app. Alla prima
// installazione non mostra nulla (ricorda solo la versione). Contiene
// anche l'elenco di tutte le versioni, a tendina, per le Impostazioni.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_changelog.dart';

abstract final class AmaterasuWhatsNew {
  static const seenKey = 'whatsNew.lastSeenVersion';

  /// The news to show for [version], or null (already seen, first run,
  /// or no entry). Remembers [version] in any case.
  static Future<AmaterasuVersionNews?> pending(
    String version,
    List<AmaterasuVersionNews> all,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getString(seenKey);
      await prefs.setString(seenKey, version);
      if (seen == null || seen == version) return null;
    } catch (_) {
      return null;
    }
    for (final entry in all) {
      if (entry.version == version) return entry;
    }
    return null;
  }

  static Future<void> show(BuildContext context, AmaterasuVersionNews entry) =>
      showAmaterasuSheet<void>(
        context,
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext)!;
          final lang = Localizations.localeOf(sheetContext).languageCode;
          return SingleChildScrollView(
            key: const Key('whats-new'),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whatsNewTitle(entry.version),
                  style: const TextStyle(
                    color: AmaterasuColors.textCream,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._lines(entry.linesFor(lang)),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: AmaterasuButton.primary(
                    key: const Key('whats-new-ok'),
                    label: l10n.whatsNewOk,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
              ],
            ),
          );
        },
      );

  static List<Widget> _lines(List<String> lines) => [
    for (final line in lines)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '• $line',
          style: const TextStyle(color: AmaterasuColors.textPrimary),
        ),
      ),
  ];

  /// Every past version, newest first, each in a fold with date and news.
  static Future<void> showAll(BuildContext context) async {
    final all = await AmaterasuChangelog.load();
    if (!context.mounted) return;
    await showAmaterasuSheet<void>(
      context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final lang = Localizations.localeOf(sheetContext).languageCode;
        final dates = MaterialLocalizations.of(sheetContext);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              key: const Key('versions-list'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  l10n.versionsTitle,
                  style: const TextStyle(
                    color: AmaterasuColors.textCream,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final (index, entry) in all.indexed)
                  ExpansionTile(
                    key: Key('version-${entry.version}'),
                    initiallyExpanded: index == 0,
                    title: Text(entry.version),
                    subtitle: entry.date == null
                        ? null
                        : Text(dates.formatMediumDate(entry.date!)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: _lines(entry.linesFor(lang)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
