import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';

import 'data_sync_settings_page.dart';
import 'data_storage_page.dart';
import 'data_connection_page.dart';

class DataSyncPage extends StatefulWidget {
  const DataSyncPage({super.key});

  @override
  State<DataSyncPage> createState() => _DataSyncPageState();
}

class _DataSyncPageState extends State<DataSyncPage> {
  bool _syncExpanded = false;
  bool _storageExpanded = false;
  bool _connectionExpanded = false;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          l10n.settingsDataSync,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          AmaterasuSettingsCard(
            icon: Icons.sync_outlined,
            title: l10n.dataSyncSection,
            subtitle: l10n.dataSyncSectionSubtitle,
            isExpanded: _syncExpanded,
            onTap: () {
              setState(() {
                _syncExpanded = !_syncExpanded;
              });
            },
            children: const [
              DataSyncSettingsPage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.storage_outlined,
            title: l10n.dataStorageSection,
            subtitle: l10n.dataStorageSectionSubtitle,
            isExpanded: _storageExpanded,
            onTap: () {
              setState(() {
                _storageExpanded = !_storageExpanded;
              });
            },
            children: const [
              DataStoragePage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.wifi_outlined,
            title: l10n.dataConnectionSection,
            subtitle: l10n.dataConnectionSectionSubtitle,
            isExpanded: _connectionExpanded,
            onTap: () {
              setState(() {
                _connectionExpanded = !_connectionExpanded;
              });
            },
            children: const [
              DataConnectionPage(),
            ],
          ),
        ],
      ),
    );
  }
}