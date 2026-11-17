// Informazioni legali: collegamento all'informativa privacy.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class InformationLegalPage extends StatelessWidget {
  const InformationLegalPage({super.key});

  static const Color _sectionColor = AmaterasuColors.surface;
  static const Color _borderColor = AmaterasuColors.borderWarm;
  static const Color _accentColor = AmaterasuColors.accentSettings;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _subtitleColor = AmaterasuColors.textMuted;
  static const Color _chevronColor = AmaterasuColors.textWarm;

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://atlaslanternproject.github.io/AmaterasuTrip/privacy.html',
  );

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(_privacyPolicyUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _InformationLegalSubItem(
          icon: Icons.policy_outlined,
          title: l10n.informationPrivacyPolicy,
          subtitle: l10n.informationPrivacyPolicySubtitle,
          onTap: _openPrivacyPolicy,
        ),
      ],
    );
  }
}

class _InformationLegalSubItem extends StatelessWidget {
  const _InformationLegalSubItem({
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
            color: InformationLegalPage._sectionColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: InformationLegalPage._borderColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: InformationLegalPage._accentColor.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: InformationLegalPage._accentColor,
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
                        color: InformationLegalPage._titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AmaterasuSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InformationLegalPage._subtitleColor,
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
                color: InformationLegalPage._chevronColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
