// Piccolo pulsante a icona con suggerimento, per le azioni rapide delle
// viste Elenco e Dettagli delle sezioni (stesse misure degli alloggi).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

class TripSectionQuickButton extends StatelessWidget {
  const TripSectionQuickButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  static const iconSize = 20.0;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: iconSize,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    color: AmaterasuColors.accentGold,
    disabledColor: AmaterasuColors.textMuted,
    icon: Icon(icon),
  );
}
