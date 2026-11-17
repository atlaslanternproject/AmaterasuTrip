import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_radius.dart';

/// Visual conventions shared by Budget dialogs.
///
/// Presentation only: no financial state or Firebase calls.
abstract final class BudgetDialogChrome {
  static const background = AmaterasuColors.surfaceCard;
  static const surface = Color(0xFF2C211C);
  static const border = AmaterasuColors.borderStrong;
  static const cream = AmaterasuColors.textPrimary;
  static const muted = AmaterasuColors.textSecondary;
  static const gold = AmaterasuColors.accentGold;
  static const orange = AmaterasuColors.accentOrange;

  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    side: BorderSide(color: border),
  );

  static const insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 20,
  );

  static const titlePadding = EdgeInsets.fromLTRB(22, 20, 22, 10);
  static const contentPadding = EdgeInsets.fromLTRB(22, 8, 22, 12);
  static const actionsPadding = EdgeInsets.fromLTRB(18, 4, 18, 16);

  static Widget header({
    required String title,
    String? subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 21, color: gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget section({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AmaterasuRadius.md),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.transparent,
          splashColor: orange.withValues(alpha: 0.10),
        ),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            iconColor: gold,
            collapsedIconColor: muted,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            leading: Icon(icon, size: 19, color: gold),
            title: Text(
              title,
              style: const TextStyle(
                color: cream,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
