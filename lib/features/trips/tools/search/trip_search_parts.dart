// Parti della pagina "Cerca": inizio (spiegazione e ricerche recenti
// con "Cancella") e riga di un risultato (icona della sezione, nome,
// sezione e frase trovata). Spostate senza cambiamenti dai risultati.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'trip_search_sources.dart';

class TripSearchStart extends StatelessWidget {
  const TripSearchStart({
    super.key,
    required this.recent,
    required this.onPick,
    required this.onClear,
  });

  final List<String> recent;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(
          l10n.searchStart,
          style: const TextStyle(color: AmaterasuColors.textSecondary),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.searchRecent,
                  style: const TextStyle(
                    color: AmaterasuColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AmaterasuButton.tertiary(
                key: const Key('search-recent-clear'),
                onPressed: onClear,
                label: l10n.searchClearRecent,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final q in recent)
                ActionChip(
                  key: Key('search-recent-$q'),
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  label: Text(q),
                  onPressed: () => onPick(q),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class TripSearchResultTile extends StatelessWidget {
  const TripSearchResultTile({
    super.key,
    required this.doc,
    required this.snippet,
    required this.onTap,
  });

  final TripSearchDoc doc;
  final String snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AmaterasuColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AmaterasuColors.borderWarm),
        ),
        child: InkWell(
          key: Key('search-result-${doc.section.name}-${doc.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(doc.section.icon, color: AmaterasuColors.accentBudget),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        doc.section.label(l10n),
                        style: const TextStyle(
                          color: AmaterasuColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (snippet != doc.title)
                        Text(
                          snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AmaterasuColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
