// Pagina "Assistenza" delle Impostazioni globali: segnala un problema,
// suggerisci un'idea e contatti, tutti per email (stesso flusso,
// AmaterasuSupportEmail). Stato dell'app in
// Informazioni; informativa e conformità in Privacy e legale.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/support/data/amaterasu_support_email.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          AmaterasuSettingsCard(
            key: const Key('support-bug'),
            icon: Icons.bug_report_outlined,
            title: l10n.supportReportProblem,
            subtitle: l10n.supportReportProblemSubtitle,
            onTap: () =>
                AmaterasuSupportEmail.report(context, AmaterasuSupportKind.bug),
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('support-idea'),
            icon: Icons.lightbulb_outline_rounded,
            title: l10n.supportSuggestIdea,
            subtitle: l10n.supportSuggestIdeaSubtitle,
            onTap: () => AmaterasuSupportEmail.report(
              context,
              AmaterasuSupportKind.idea,
            ),
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            key: const Key('support-contacts'),
            icon: Icons.mail_outline_rounded,
            title: l10n.supportContacts,
            subtitle: l10n.supportContactsSubtitle,
            onTap: AmaterasuSupportEmail.contact,
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
