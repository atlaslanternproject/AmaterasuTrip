import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacy),
      ),
      body: Center(
        child: Text(l10n.settingsPlaceholder),
      ),
    );
  }
}
