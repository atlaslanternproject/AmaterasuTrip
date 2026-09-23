import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class DataConnectionPage extends StatefulWidget {
  const DataConnectionPage({super.key});

  @override
  State<DataConnectionPage> createState() => _DataConnectionPageState();
}

class _DataConnectionPageState extends State<DataConnectionPage> {
  static const String _wifiOnlyKey = 'data_sync_wifi_only';
  static const String _automaticDownloadsKey = 'data_automatic_downloads';

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  bool _wifiOnly = true;
  bool _automaticDownloads = false;
  bool _loading = true;

  bool get _mobileData => !_wifiOnly;

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
      _wifiOnly = preferences.getBool(_wifiOnlyKey) ?? true;
      _automaticDownloads =
          preferences.getBool(_automaticDownloadsKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _setWifiOnly(bool value) async {
    setState(() {
      _wifiOnly = value;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_wifiOnlyKey, value);
  }

  Future<void> _setMobileData(bool value) async {
    await _setWifiOnly(!value);
  }

  Future<void> _setAutomaticDownloads(bool value) async {
    setState(() {
      _automaticDownloads = value;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_automaticDownloadsKey, value);
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
        _ConnectionSwitchItem(
          icon: Icons.wifi,
          title: l10n.dataWifiOnly,
          subtitle: l10n.dataWifiOnlySubtitle,
          value: _wifiOnly,
          onChanged: _setWifiOnly,
        ),
        const SizedBox(height: 8),
        _ConnectionSwitchItem(
          icon: Icons.signal_cellular_alt,
          title: l10n.dataMobileData,
          subtitle: l10n.dataMobileDataSubtitle,
          value: _mobileData,
          onChanged: _setMobileData,
        ),
        const SizedBox(height: 8),
        _ConnectionSwitchItem(
          icon: Icons.download_outlined,
          title: l10n.dataAutomaticDownloads,
          subtitle: l10n.dataAutomaticDownloadsSubtitle,
          value: _automaticDownloads,
          onChanged: _setAutomaticDownloads,
        ),
      ],
    );
  }
}

class _ConnectionSwitchItem extends StatelessWidget {
  const _ConnectionSwitchItem({
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
        color: _DataConnectionPageState._sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _DataConnectionPageState._borderColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _DataConnectionPageState._accentColor
                    .withValues(alpha: 0.65),
              ),
            ),
            child: const Icon(
              Icons.circle,
              color: _DataConnectionPageState._accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _DataConnectionPageState._titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _DataConnectionPageState._subtitleColor,
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
            activeThumbColor: _DataConnectionPageState._accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}