// I quattro tipi di pulsante dell'app (docs/design/DIRETTIVE-UI.md):
// principale pieno arancio, secondario a contorno, terziario solo testo e
// distruttivo rosso (solo per eliminare). Per il grande pulsante da 56 a
// tutta larghezza resta AmaterasuPrimaryButton.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

enum AmaterasuButtonKind { primary, secondary, tertiary, destructive }

class AmaterasuButton extends StatelessWidget {
  const AmaterasuButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  const AmaterasuButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : kind = AmaterasuButtonKind.primary;

  const AmaterasuButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : kind = AmaterasuButtonKind.secondary;

  const AmaterasuButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : kind = AmaterasuButtonKind.tertiary;

  const AmaterasuButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : kind = AmaterasuButtonKind.destructive;

  final AmaterasuButtonKind kind;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    final iconWidget = icon == null ? null : Icon(icon, size: 18);
    switch (kind) {
      case AmaterasuButtonKind.primary:
      case AmaterasuButtonKind.destructive:
        final style = FilledButton.styleFrom(
          backgroundColor: kind == AmaterasuButtonKind.primary
              ? AmaterasuColors.accentBudget
              : AmaterasuColors.error,
        );
        return iconWidget == null
            ? FilledButton(style: style, onPressed: onPressed, child: text)
            : FilledButton.icon(
                style: style,
                onPressed: onPressed,
                icon: iconWidget,
                label: text,
              );
      case AmaterasuButtonKind.secondary:
        final style = OutlinedButton.styleFrom(
          foregroundColor: AmaterasuColors.textPrimary,
          side: const BorderSide(color: AmaterasuColors.borderAccent),
        );
        return iconWidget == null
            ? OutlinedButton(style: style, onPressed: onPressed, child: text)
            : OutlinedButton.icon(
                style: style,
                onPressed: onPressed,
                icon: iconWidget,
                label: text,
              );
      case AmaterasuButtonKind.tertiary:
        final style = TextButton.styleFrom(
          foregroundColor: AmaterasuColors.textSecondary,
        );
        return iconWidget == null
            ? TextButton(style: style, onPressed: onPressed, child: text)
            : TextButton.icon(
                style: style,
                onPressed: onPressed,
                icon: iconWidget,
                label: text,
              );
    }
  }
}
