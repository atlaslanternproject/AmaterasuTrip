// Pulsante "Filtri" compatto per le intestazioni (come nella Bucket List):
// icona dei filtri con il numero dei filtri attivi in un pallino; apre il
// pannello condiviso dei filtri.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuFilterIconButton extends StatelessWidget {
  const AmaterasuFilterIconButton({
    super.key,
    required this.keyPrefix,
    required this.activeCount,
    required this.onPressed,
  });

  final String keyPrefix;
  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: Key('$keyPrefix-filters'),
    tooltip: AppLocalizations.of(context)!.filtersTitle,
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: activeCount > 0,
      backgroundColor: AmaterasuColors.primary,
      label: Text('$activeCount', key: Key('$keyPrefix-filters-count')),
      child: const Icon(Icons.tune_rounded, color: AmaterasuColors.accentGold),
    ),
  );
}
