import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class InformationCreditsPage extends StatelessWidget {
  const InformationCreditsPage({super.key});

  static const Color _sectionColor = Color(0xFF1A1512);
  static const Color _borderColor = Color(0xFF3A2A20);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _InformationCreditsSubItem(
          icon: Icons.groups_outlined,
          title: l10n.informationCreditsDevelopedBy,
          subtitle: l10n.informationCreditsTeam,
        ),
        const SizedBox(height: 10),
        _InformationCreditsSubItem(
          icon: Icons.code_outlined,
          title: l10n.informationCreditsTechnologies,
          subtitle: l10n.informationCreditsTechnologiesSubtitle,
        ),
      ],
    );
  }
}

class _InformationCreditsSubItem extends StatelessWidget {
  const _InformationCreditsSubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InformationCreditsPage._sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: InformationCreditsPage._borderColor,
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
                color: InformationCreditsPage._accentColor.withValues(
                  alpha: 0.65,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: InformationCreditsPage._accentColor,
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
                    color: InformationCreditsPage._titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: InformationCreditsPage._subtitleColor,
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