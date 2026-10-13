import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class AccountSecurityRecoveryPage extends StatelessWidget {
  const AccountSecurityRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF100C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C0A),
        elevation: 0,
        title: Text(l10n.accountRecoveryTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: const [AccountSecurityRecoveryContent()],
      ),
    );
  }
}

/// Informazioni sul recupero, mostrate all'interno della card Account.
/// Non genera codici e non attiva il recupero crittografico.
class AccountSecurityRecoveryContent extends StatelessWidget {
  const AccountSecurityRecoveryContent({super.key});

  static const _surface = Color(0xFF211A16);
  static const _border = Color(0xFF3A2A20);
  static const _accent = Color(0xFFE28A32);
  static const _title = Color(0xFFF2E7D5);
  static const _muted = Color(0xFF9E9287);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: _accent, size: 28),
              const SizedBox(height: 12),
              Text(
                l10n.accountRecoveryStatus,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.accountRecoveryStatusTitle,
                style: const TextStyle(
                  color: _title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountRecoveryStatusDescription,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.accountRecoverySectionTitle,
          style: const TextStyle(
            color: _title,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _RecoveryInfoItem(
          icon: Icons.key_outlined,
          title: l10n.accountRecoveryCodeTitle,
          description: l10n.accountRecoveryCodeDescription,
        ),
        const SizedBox(height: 8),
        _RecoveryInfoItem(
          icon: Icons.lock_outline,
          title: l10n.accountRecoveryStorageTitle,
          description: l10n.accountRecoveryStorageDescription,
        ),
        const SizedBox(height: 8),
        _RecoveryInfoItem(
          icon: Icons.devices_outlined,
          title: l10n.accountRecoveryDeviceTitle,
          description: l10n.accountRecoveryDeviceDescription,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: _accent, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.accountRecoveryNotice,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecoveryInfoItem extends StatelessWidget {
  const _RecoveryInfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AccountSecurityRecoveryContent._surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AccountSecurityRecoveryContent._border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AccountSecurityRecoveryContent._accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AccountSecurityRecoveryContent._title,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: AccountSecurityRecoveryContent._muted,
                    fontSize: 12,
                    height: 1.45,
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
