// Barra dei filtri condivisa (nata negli alloggi): pulsante "Filtri" con il
// numero di filtri attivi, ordine scelto, quanti elementi si vedono e
// "Azzera filtri". Uguale in tutte le sezioni.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuFilterBar extends StatelessWidget {
  const AmaterasuFilterBar({
    super.key,
    required this.keyPrefix,
    required this.activeCount,
    this.shown,
    this.total,
    required this.onOpen,
    required this.onClear,
    this.sortLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 10),
  });

  final String keyPrefix;
  final int activeCount;
  final int? shown;
  final int? total;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  /// Chosen order, shown next to the button.
  final String? sortLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = activeCount > 0;
    final sort = sortLabel;
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            key: Key('$keyPrefix-filters'),
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor: active
                  ? AmaterasuColors.accentGold
                  : AmaterasuColors.textPrimary,
              backgroundColor: active
                  ? AmaterasuColors.accentBudget.withValues(alpha: 0.16)
                  : null,
              side: BorderSide(
                color: active
                    ? AmaterasuColors.accentBudget
                    : AmaterasuColors.borderStrong,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              active ? l10n.filtersActive(activeCount) : l10n.filtersTitle,
            ),
          ),
          if (sort != null)
            Text(
              sort,
              style: const TextStyle(
                color: AmaterasuColors.textMuted,
                fontSize: 12,
              ),
            ),
          if (active) ...[
            if (shown != null && total != null)
              Text(
                l10n.filtersShown(shown!, total!),
                key: Key('$keyPrefix-filters-count'),
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            TextButton(
              key: Key('$keyPrefix-filters-clear'),
              onPressed: onClear,
              child: Text(l10n.filtersClear),
            ),
          ],
        ],
      ),
    );
  }
}
