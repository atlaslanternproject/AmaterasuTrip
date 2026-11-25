// Pagina "Assistenza e privacy" delle Impostazioni globali (Extra F):
// segnala un problema, suggerisci un'idea, stato dell'app (versione e data
// dell'ultimo aggiornamento), informativa privacy online e pagina
// "Conformità e normative".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amaterasutrip/core/changelog/amaterasu_changelog.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/support/data/feedback_repository.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'feedback_sheet.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const privacyUrl =
      'https://atlaslanternproject.github.io/AmaterasuTrip/privacy.html';

  /// Installed version and the date of its news (last update).
  static Future<(String, DateTime?)> _status() async {
    final version = (await PackageInfo.fromPlatform()).version;
    DateTime? date;
    try {
      for (final entry in await AmaterasuChangelog.load()) {
        if (entry.version == version) date = entry.date;
      }
    } catch (_) {}
    return (version, date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AmaterasuColors.surfaceDeep,
        elevation: 0,
        title: Text(
          l10n.supportTitle,
          style: const TextStyle(
            color: AmaterasuColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        key: const Key('support-page'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          AmaterasuSettingsCard(
            key: const Key('support-bug'),
            icon: Icons.bug_report_outlined,
            title: l10n.supportReportProblem,
            subtitle: l10n.supportReportProblemSubtitle,
            onTap: () => showFeedbackSheet(context, FeedbackKind.bug),
          ),
          AmaterasuSettingsCard(
            key: const Key('support-idea'),
            icon: Icons.lightbulb_outline_rounded,
            title: l10n.supportSuggestIdea,
            subtitle: l10n.supportSuggestIdeaSubtitle,
            onTap: () => showFeedbackSheet(context, FeedbackKind.idea),
          ),
          FutureBuilder(
            future: _status(),
            builder: (context, snap) {
              final (version, date) = snap.data ?? ('—', null);
              final when = date == null
                  ? '—'
                  : MaterialLocalizations.of(context).formatMediumDate(date);
              return AmaterasuSettingsCard(
                key: const Key('support-status'),
                icon: Icons.verified_outlined,
                title: l10n.supportAppStatus,
                subtitle: l10n.supportAppStatusValue(version, when),
                onTap: () => context.push('/settings/information'),
              );
            },
          ),
          AmaterasuSettingsCard(
            key: const Key('support-privacy'),
            icon: Icons.privacy_tip_outlined,
            title: l10n.supportPrivacy,
            subtitle: l10n.supportPrivacySubtitle,
            onTap: () => AmaterasuLinkOpener.openWebLink(
              context,
              privacyUrl,
              invalidMessage: l10n.commonLinkInvalid,
              failedMessage: l10n.commonLinkOpenFailed,
              copyLabel: l10n.commonLinkCopy,
            ),
          ),
          AmaterasuSettingsCard(
            key: const Key('support-compliance'),
            icon: Icons.gavel_rounded,
            title: l10n.supportCompliance,
            subtitle: l10n.supportComplianceSubtitle,
            onTap: () => context.push('/settings/support/compliance'),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.supportNoTracking,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
