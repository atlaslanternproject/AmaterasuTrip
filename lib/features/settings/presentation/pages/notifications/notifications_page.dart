import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: Center(child: Text(l10n.settingsPlaceholder)),
    );
  }
}
