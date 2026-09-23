import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class DataSyncSettingsPage extends StatefulWidget {
  const DataSyncSettingsPage({super.key});

  @override
  State<DataSyncSettingsPage> createState() => _DataSyncSettingsPageState();
}

class _DataSyncSettingsPageState extends State<DataSyncSettingsPage> {
  static const String _syncEnabledKey = 'data_sync_enabled';

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _disabledColor = Color(0xFF6F665F);

  bool _syncEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _syncEnabled = preferences.getBool(_syncEnabledKey) ?? true;
      _loading = false;
    });
  }

  Future<void> _setSyncEnabled(bool value) async {
    setState(() {
      _syncEnabled = value;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_syncEnabledKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: _accentColor,
          ),
        ),
      );
    }

    return Column(
      children: [
        _SwitchItem(
          icon: Icons.sync,
          title: l10n.dataSyncEnabled,
          subtitle: l10n.dataSyncEnabledSubtitle,
          value: _syncEnabled,
          onChanged: _setSyncEnabled,
        ),
        const SizedBox(height: 8),
        _InfoItem(
          icon: Icons.sync_outlined,
          title: l10n.dataSyncNow,
          subtitle: l10n.dataSyncNowSubtitle,
          enabled: false,
        ),
        const SizedBox(height: 8),
        _InfoItem(
          icon: Icons.history,
          title: l10n.dataSyncLast,
          subtitle: l10n.dataSyncNever,
          enabled: false,
        ),
        const SizedBox(height: 8),
        _InfoItem(
          icon: Icons.cloud_outlined,
          title: l10n.dataSyncStatus,
          subtitle: l10n.dataSyncStatusUnavailable,
          enabled: false,
        ),
      ],
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DataSyncSettingsPageState._sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _DataSyncSettingsPageState._borderColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _DataSyncSettingsPageState._titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _DataSyncSettingsPageState._subtitleColor,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeThumbColor: _DataSyncSettingsPageState._accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? _DataSyncSettingsPageState._titleColor
        : _DataSyncSettingsPageState._disabledColor;

    final subtitleColor = enabled
        ? _DataSyncSettingsPageState._subtitleColor
        : _DataSyncSettingsPageState._disabledColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DataSyncSettingsPageState._sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _DataSyncSettingsPageState._borderColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        children: [
          _SettingsIcon(
            icon: icon,
            enabled: enabled,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    this.enabled = true,
  });

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? _DataSyncSettingsPageState._accentColor
        : _DataSyncSettingsPageState._disabledColor;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.65),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}