import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class InformationSupportPage extends StatelessWidget {
  const InformationSupportPage({super.key});

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _chevronColor = Color(0xFFB89B7A);

  static const String _supportEmail = 'atlaslanternproject@gmail.com';

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
    );

    await launchUrl(uri);
  }

  Future<void> _reportProblem(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final packageInfo = await PackageInfo.fromPlatform();

    final subject = Uri.encodeComponent(
      l10n.informationReportProblemSubject,
    );

    final body = Uri.encodeComponent(
      l10n.informationReportProblemBody(
        packageInfo.version,
        packageInfo.buildNumber,
      ),
    );

    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=$subject&body=$body',
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _InformationSupportSubItem(
          icon: Icons.email_outlined,
          title: l10n.informationContactUs,
          subtitle: _supportEmail,
          onTap: _contactSupport,
        ),
        const SizedBox(height: 10),
        _InformationSupportSubItem(
          icon: Icons.bug_report_outlined,
          title: l10n.informationReportProblem,
          subtitle: l10n.informationReportProblemSubtitle,
          onTap: () => _reportProblem(context),
        ),
      ],
    );
  }
}

class _InformationSupportSubItem extends StatelessWidget {
  const _InformationSupportSubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: InformationSupportPage._sectionColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: InformationSupportPage._borderColor,
              width: 1,
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
                    color: InformationSupportPage._accentColor.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: InformationSupportPage._accentColor,
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
                        color: InformationSupportPage._titleColor,
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
                        color: InformationSupportPage._subtitleColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.open_in_new,
                color: InformationSupportPage._chevronColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}