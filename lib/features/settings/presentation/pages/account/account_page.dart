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
        ],
      ),
    );
  }
}