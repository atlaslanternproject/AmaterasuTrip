import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyExportPage extends StatelessWidget {
  const PrivacyExportPage({super.key});

  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _textColor = Color(0xFFB8AAA0);
  static const Color _accentColor = Color(0xFFD49A52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.download_for_offline_outlined,
          color: _accentColor,
          size: 40,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.privacyExportHeading,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.privacyExportBody,
          style: const TextStyle(color: _textColor, fontSize: 14, height: 1.55),
        ),
      ],
    );
  }
}
