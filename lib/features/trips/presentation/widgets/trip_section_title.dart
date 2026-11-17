// Titolo di sezione con icona e colore di accento.

import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripSectionTitle extends StatelessWidget {
  const TripSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;

  static const Color _titleColor = AmaterasuColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: accentColor),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
