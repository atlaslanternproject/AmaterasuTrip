// Riga etichetta-valore usata nella card del profilo.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.alignTop = false,
  });

  static const Color _accentColor = AmaterasuColors.accentSettings;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _subtitleColor = AmaterasuColors.textMuted;

  final IconData icon;
  final String label;
  final String value;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: alignTop ? 2 : 0),
            child: Icon(icon, color: _accentColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _subtitleColor, fontSize: 12),
                ),
                const SizedBox(height: AmaterasuSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(color: _titleColor, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
