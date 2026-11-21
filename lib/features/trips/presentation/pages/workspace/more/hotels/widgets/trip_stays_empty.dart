// Stato vuoto di Hotel/Alloggi: icona, titolo, spiegazione e pulsante per
// aggiungere il primo alloggio, nello stile delle pagine del workspace.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysEmpty extends StatelessWidget {
  const TripStaysEmpty({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AmaterasuSpacing.lg),
        child: Container(
          key: const Key('stays-empty'),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: AmaterasuColors.surfaceWarm,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AmaterasuColors.borderAccent.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AmaterasuColors.accentBudget.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AmaterasuColors.accentBudget.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(Icons.hotel_rounded,
                    color: AmaterasuColors.accentBudget, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.staysEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AmaterasuSpacing.sm),
              Text(
                l10n.staysEmptyBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('stays-empty-add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AmaterasuColors.accentBudget,
                  ),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.staysAdd),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
