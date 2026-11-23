// Stato vuoto di una sezione: icona grande, un breve testo e il pulsante
// per aggiungere il primo elemento, centrati come negli alloggi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripSectionEmpty extends StatelessWidget {
  const TripSectionEmpty({
    super.key,
    required this.keyPrefix,
    required this.icon,
    required this.text,
    required this.addLabel,
    required this.onAdd,
  });

  final String keyPrefix;
  final IconData icon;
  final String text;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          key: Key('$keyPrefix-empty'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AmaterasuColors.accentBudget.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AmaterasuColors.accentBudget),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AmaterasuColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AmaterasuColors.accentBudget,
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
