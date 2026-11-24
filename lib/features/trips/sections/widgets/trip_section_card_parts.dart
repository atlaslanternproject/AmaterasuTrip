// Parti piccole della card delle sezioni: riquadro con l'icona della
// sezione e riga di dettaglio con icona e testo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'trip_section_entry.dart';

class TripSectionCardBadge extends StatelessWidget {
  const TripSectionCardBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AmaterasuColors.accentBudget.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AmaterasuColors.accentBudget, size: 22),
  );
}

class TripSectionCardLine extends StatelessWidget {
  const TripSectionCardLine(this.line, {super.key});

  final TripSectionLine line;

  @override
  Widget build(BuildContext context) => Padding(
    key: line.key,
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(line.icon, size: 16, color: AmaterasuColors.textSecondary),
        const SizedBox(width: AmaterasuSpacing.sm),
        Expanded(
          child: Text(
            line.text,
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
