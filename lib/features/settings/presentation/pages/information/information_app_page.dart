// Stato dell'app (Informazioni): nome, versione e build; toccando la
// versione si apre l'elenco di tutte le versioni con le novità.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amaterasutrip/core/changelog/amaterasu_whats_new.dart';
import 'information_sub_item.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class InformationAppPage extends StatefulWidget {
  const InformationAppPage({super.key});

  @override
  State<InformationAppPage> createState() => _InformationAppPageState();
}

class _InformationAppPageState extends State<InformationAppPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        InformationSubItem(
          icon: Icons.apps_outlined,
          title: l10n.informationAppName,
          subtitle: 'Amaterasu Trip',
          onTap: () {},
        ),
        InformationSubItem(
          icon: Icons.new_releases_outlined,
          title: l10n.informationVersion,
          subtitle: _packageInfo?.version ?? '—',
          // Opens every past version with its news (Extra A).
          onTap: () => AmaterasuWhatsNew.showAll(context),
        ),
        InformationSubItem(
          icon: Icons.tag_outlined,
          title: l10n.informationBuild,
          subtitle: _packageInfo?.buildNumber ?? '—',
          onTap: () {},
        ),
      ],
    );
  }
}
