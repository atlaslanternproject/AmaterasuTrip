// Pulsante "Modifica" uguale in tutta l'app: matita oro in alto nella
// card; su schermo largo (almeno 600 punti) matita con la parola
// "Modifica".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuEditButton extends StatelessWidget {
  const AmaterasuEditButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.uiEdit;
    const icon = Icon(Icons.edit_outlined, color: AmaterasuColors.accentGold);
    if (MediaQuery.sizeOf(context).width >= 600) {
      return TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AmaterasuColors.accentGold,
        ),
        icon: icon,
        label: Text(label),
      );
    }
    return IconButton(tooltip: label, onPressed: onPressed, icon: icon);
  }
}
