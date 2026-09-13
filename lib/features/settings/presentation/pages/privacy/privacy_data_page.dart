import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyDataPage extends StatelessWidget {
  const PrivacyDataPage({super.key});

  static const Color _backgroundColor = Color(0xFF120F0D);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _textColor = Color(0xFFB8AAA0);
  static const Color _accentColor = Color(0xFFD49A52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        title: Text(l10n.privacyDataTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: l10n.privacyPolicyOverviewTitle,
            body: l10n.privacyPolicyOverviewBody,
          ),
          _Section(
            title: l10n.privacyPolicyCollectedDataTitle,
            body: l10n.privacyPolicyCollectedDataBody,
          ),
          _Section(
            title: l10n.privacyPolicyPurposeTitle,
            body: l10n.privacyPolicyPurposeBody,
          ),
          _Section(
            title: l10n.privacyPolicyFirebaseTitle,
            body: l10n.privacyPolicyFirebaseBody,
          ),
          _Section(
            title: l10n.privacyPolicyGoogleTitle,
            body: l10n.privacyPolicyGoogleBody,
          ),
          _Section(
            title: l10n.privacyPolicyStorageTitle,
            body: l10n.privacyPolicyStorageBody,
          ),
          _Section(
            title: l10n.privacyPolicyDeletionTitle,
            body: l10n.privacyPolicyDeletionBody,
          ),
          _Section(
            title: l10n.privacyPolicySecurityTitle,
            body: l10n.privacyPolicySecurityBody,
          ),
          _Section(
            title: l10n.privacyPolicyChangesTitle,
            body: l10n.privacyPolicyChangesBody,
          ),
          _Section(
            title: l10n.privacyPolicyContactTitle,
            body: l10n.privacyPolicyContactBody,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

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
              color: PrivacyDataPage._accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: PrivacyDataPage._textColor,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
