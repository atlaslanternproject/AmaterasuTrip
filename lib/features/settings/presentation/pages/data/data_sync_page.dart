import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class DataSyncPage extends StatelessWidget {
  const DataSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDataSync)),
      body: Center(child: Text(l10n.settingsPlaceholder)),
    );
  }
}
