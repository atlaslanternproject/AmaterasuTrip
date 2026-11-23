// Blocco di un editor delle sezioni: titolo con icona e colore di accento,
// contenuto sotto, nello stile dei blocchi dell'editor degli alloggi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class TripSectionBlock extends StatelessWidget {
  const TripSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AmaterasuColors.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AmaterasuColors.borderWarm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AmaterasuColors.accentBudget),
            const SizedBox(width: AmaterasuSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}
