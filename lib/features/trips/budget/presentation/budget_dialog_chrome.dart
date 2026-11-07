import 'package:flutter/material.dart';

/// Visual conventions shared by Budget dialogs.
///
/// Presentation only: no financial state or Firebase calls.
abstract final class BudgetDialogChrome {
  static const background = Color(0xFF231915);
  static const surface = Color(0xFF2C211C);
  static const border = Color(0xFF49352A);
  static const cream = Color(0xFFF2E7D5);
  static const muted = Color(0xFFB7A99B);
  static const gold = Color(0xFFE3A66C);
  static const orange = Color(0xFFE17A43);

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
        borderRadius: BorderRadius.circular(14),
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
