// Stato vuoto di Hotel/Alloggi: icona, titolo, spiegazione e pulsante per
// aggiungere il primo alloggio, nello stile delle pagine del workspace.
// Con testi e pulsante diversi serve anche per "nessun alloggio con
// questi filtri".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysEmpty extends StatelessWidget {
  const TripStaysEmpty({
    super.key,
    this.onAdd,
    this.boxKey = const Key('stays-empty'),
    this.icon = Icons.hotel_rounded,
    this.title,
    this.body,
    this.actionKey = const Key('stays-empty-add'),
    this.actionIcon = Icons.add,
    this.actionLabel,
    this.onAction,
  });

  /// "Aggiungi alloggio" (the default action).
  final VoidCallback? onAdd;
  final Key boxKey;
  final IconData icon;
  final String? title;
  final String? body;
  final Key actionKey;
  final IconData actionIcon;
  final String? actionLabel;

  /// Replaces [onAdd] together with [actionLabel].
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = onAction ?? onAdd;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AmaterasuSpacing.lg),
        child: Container(
          key: boxKey,
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
                child: Icon(icon,
                    color: AmaterasuColors.accentBudget, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title ?? l10n.staysEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AmaterasuColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AmaterasuSpacing.sm),
              Text(
                body ?? l10n.staysEmptyBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: actionKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: AmaterasuColors.accentBudget,
                  ),
                  onPressed: action,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel ?? l10n.staysAdd),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
