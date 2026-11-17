// Intestazione del workspace del viaggio (oggi non usata da nessuna pagina).

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

// TODO(audit): C1 widget non usato da nessuna pagina: decidere se eliminarlo o usarlo.
class TripWorkspaceHeader extends StatelessWidget {
  const TripWorkspaceHeader({
    super.key,
    required this.title,
    required this.destination,
    required this.dateRange,
    required this.onSettingsTap,
  });

  final String title;
  final String destination;
  final String dateRange;
  final VoidCallback onSettingsTap;

  static const Color _surfaceColor = AmaterasuColors.surfaceWarm;
  static const Color _borderColor = AmaterasuColors.borderAccent;
  static const Color _accentColor = AmaterasuColors.accentBudget;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _secondaryTextColor = AmaterasuColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: _accentColor,
              size: 29,
            ),
          ),
          const SizedBox(width: AmaterasuSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AmaterasuSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _secondaryTextColor,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: _secondaryTextColor,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        dateRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AmaterasuSpacing.sm),
          IconButton(
            onPressed: onSettingsTap,
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: _accentColor.withValues(alpha: 0.10),
              foregroundColor: _titleColor,
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}
