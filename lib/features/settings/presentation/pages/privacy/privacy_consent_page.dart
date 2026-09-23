import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyConsentPage extends StatelessWidget {
  const PrivacyConsentPage({super.key});

  static const Color _textColor = Color(0xFFB8AAA0);
  static const Color _accentColor = Color(0xFFD49A52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyConsentIntro,
          style: const TextStyle(color: _textColor, fontSize: 14, height: 1.55),
        ),
        const SizedBox(height: 24),
        _ConsentSection(
          title: l10n.privacyConsentRequiredTitle,
          body: l10n.privacyConsentRequiredBody,
        ),
        _ConsentSection(
          title: l10n.privacyConsentOptionalTitle,
          body: l10n.privacyConsentOptionalBody,
        ),
        _ConsentSection(
          title: l10n.privacyConsentFutureTitle,
          body: l10n.privacyConsentFutureBody,
        ),
      ],
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PrivacyConsentPage._accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: PrivacyConsentPage._textColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
