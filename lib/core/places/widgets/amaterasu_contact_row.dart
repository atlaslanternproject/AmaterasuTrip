// Riga del pop-up "Contatta": icona, tipo di contatto, valore e due
// pulsanti (azione principale come "Chiama" e "Copia").

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuContactRow extends StatelessWidget {
  const AmaterasuContactRow({
    super.key,
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
    required this.onCopy,
    this.keyPrefix = 'place-contact',
  });

  /// Start of the button keys.
  final String keyPrefix;

  /// Used in the button keys ({keyPrefix}-{id}-action and -copy).
  final String id;
  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
    decoration: BoxDecoration(
      color: AmaterasuColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AmaterasuColors.borderWarm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AmaterasuColors.accentBudget),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AmaterasuColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            color: AmaterasuColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                key: Key('$keyPrefix-$id-copy'),
                onPressed: onCopy,
                style: TextButton.styleFrom(
                  foregroundColor: AmaterasuColors.textSecondary,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.placesContactCopy),
              ),
              FilledButton.tonal(
                key: Key('$keyPrefix-$id-action'),
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AmaterasuColors.accentBudget.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: AmaterasuColors.accentGold,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
