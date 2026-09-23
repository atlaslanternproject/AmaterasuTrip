import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'information_licenses_page.dart';
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
        _InformationSubItem(
          icon: Icons.apps_outlined,
          title: l10n.informationAppName,
          subtitle: 'Amaterasu Trip',
          onTap: () {},
        ),
        _InformationSubItem(
          icon: Icons.new_releases_outlined,
          title: l10n.informationVersion,
          subtitle: _packageInfo?.version ?? '—',
          onTap: () {},
        ),
        _InformationSubItem(
          icon: Icons.tag_outlined,
          title: l10n.informationBuild,
          subtitle: _packageInfo?.buildNumber ?? '—',
          onTap: () {},
        ),
        _InformationSubItem(
          icon: Icons.description_outlined,
          title: l10n.informationOpenSourceLicenses,
          subtitle: l10n.informationOpenSourceLicensesSubtitle,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const InformationLicensesPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InformationSubItem extends StatelessWidget {
  const _InformationSubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _chevronColor = Color(0xFFB89B7A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: _sectionColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
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
                    color: _accentColor.withValues(alpha: 0.65),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _accentColor,
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
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _subtitleColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: _chevronColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}