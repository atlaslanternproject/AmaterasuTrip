// Avviso solo informativo in cima a una sezione (es. coincidenze strette
// dei trasporti): icona, una riga per ogni avviso e un breve suggerimento,
// nello stile dell'avviso delle notti senza alloggio.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class TripSectionNotice extends StatelessWidget {
  const TripSectionNotice({
    super.key,
    required this.icon,
    required this.lines,
    this.hint,
  });

  final IconData icon;
  final List<String> lines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AmaterasuSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AmaterasuColors.accentGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Text(
                    line,
                    style: const TextStyle(
                      color: AmaterasuColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(
                      color: AmaterasuColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
