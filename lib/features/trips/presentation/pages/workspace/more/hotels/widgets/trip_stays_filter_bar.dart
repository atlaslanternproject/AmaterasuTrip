// Barra sopra l'elenco degli alloggi: pulsante "Filtri" con il numero di
// filtri attivi, ordine scelto e pulsante per azzerare i filtri.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_filter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripStaysFilterBar extends StatelessWidget {
  const TripStaysFilterBar({
    super.key,
    required this.filter,
    required this.shown,
    required this.total,
    required this.onOpen,
    required this.onClear,
  });

  final TripStaysFilter filter;
  final int shown;
  final int total;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = filter.activeCount;
    final active = count > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            key: const Key('stays-filters'),
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  active ? AmaterasuColors.accentGold : AmaterasuColors.textPrimary,
              backgroundColor: active
                  ? AmaterasuColors.accentBudget.withValues(alpha: 0.16)
                  : null,
              side: BorderSide(
                color: active
                    ? AmaterasuColors.accentBudget
                    : AmaterasuColors.borderStrong,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(active ? l10n.staysFiltersActive(count) : l10n.staysFilters),
          ),
          Text(
            filter.sort == TripStaysSort.checkInAsc
                ? l10n.staysSortAsc
                : l10n.staysSortDesc,
            style: const TextStyle(color: AmaterasuColors.textMuted, fontSize: 12),
          ),
          if (active) ...[
            Text(
              l10n.staysFiltersShown(shown, total),
              key: const Key('stays-filters-count'),
              style: const TextStyle(
                  color: AmaterasuColors.textSecondary, fontSize: 12),
            ),
            TextButton(
              key: const Key('stays-filters-clear'),
              onPressed: onClear,
              child: Text(l10n.staysFiltersClear),
            ),
          ],
        ],
      ),
    );
  }
}
