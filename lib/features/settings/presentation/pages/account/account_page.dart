import 'package:flutter/material.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/settings/amaterasu_settings_card.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/account/account_email_page.dart';
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}
class _AccountPageState extends State<AccountPage> {
  bool _emailExpanded = false;
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _chevronColor = Color(0xFFB89B7A);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          l10n.settingsAccount,
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
            icon: Icons.email_outlined,
            title: l10n.accountEmail,
            subtitle: l10n.accountEmailSubtitle,
            isExpanded: _emailExpanded,
            onTap: () {
              setState(() {
                _emailExpanded = !_emailExpanded;
              });
            },
            children: const [
              AccountEmailPage(),
            ],
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.password_outlined,
            title: l10n.accountPassword,
            subtitle: l10n.accountPasswordSubtitle,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.link_outlined,
            title: l10n.accountLinkedAccounts,
            subtitle: l10n.accountLinkedAccountsSubtitle,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.devices_outlined,
            title: l10n.accountSession,
            subtitle: l10n.accountSessionSubtitle,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          AmaterasuSettingsCard(
            icon: Icons.manage_accounts_outlined,
            title: l10n.accountDelete,
            subtitle: l10n.accountDeleteDescription,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _AccountActionCard(
            icon: Icons.logout,
            title: l10n.accountLogout,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _AccountPageState._sectionColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _AccountPageState._borderColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _AccountPageState._accentColor.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _AccountPageState._accentColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _AccountPageState._titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: _AccountPageState._chevronColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}