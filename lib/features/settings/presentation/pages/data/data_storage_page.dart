import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class DataStoragePage extends StatelessWidget {
  const DataStoragePage({super.key});

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _disabledColor = Color(0xFF6F665F);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _StorageItem(
          icon: Icons.offline_pin_outlined,
          title: l10n.dataOfflineAvailable,
          subtitle: l10n.dataOfflineAvailableSubtitle,
          enabled: false,
        ),
        const SizedBox(height: 8),
        _StorageItem(
          icon: Icons.sd_storage_outlined,
          title: l10n.dataStorageUsed,
          subtitle: l10n.dataStorageUsedUnavailable,
          enabled: false,
        ),
        const SizedBox(height: 8),
        _StorageItem(
          icon: Icons.folder_open_outlined,
          title: l10n.dataManageOffline,
          subtitle: l10n.dataManageOfflineSubtitle,
          enabled: false,
        ),
        const SizedBox(height: 8),
        _StorageItem(
          icon: Icons.delete_outline,
          title: l10n.dataClearOffline,
          subtitle: l10n.dataClearOfflineSubtitle,
          enabled: false,
        ),
      ],
    );
  }
}

class _StorageItem extends StatelessWidget {
  const _StorageItem({
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
    final color = enabled
        ? DataStoragePage._accentColor
        : DataStoragePage._disabledColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DataStoragePage._sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DataStoragePage._borderColor,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
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