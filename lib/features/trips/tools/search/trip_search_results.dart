// Risultati della pagina "Cerca": filtro per sezione (chip comuni delle
// sezioni), numero di risultati e righe trovate, a pagine da 20; stati di
// caricamento ed errore con "Riprova".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'trip_search_parts.dart';
import 'trip_search_sources.dart';
import 'trip_search_text.dart';

class TripSearchResults extends ConsumerStatefulWidget {
  const TripSearchResults({
    super.key,
    required this.tripId,
    required this.query,
    required this.onOpen,
  });

  final String tripId;
  final String query;
  final ValueChanged<TripSearchDoc> onOpen;

  @override
  ConsumerState<TripSearchResults> createState() => _TripSearchResultsState();
}

class _TripSearchResultsState extends ConsumerState<TripSearchResults> {
  static const _page = 20;
  TripSearchSection? _section;
  int _shown = _page;

  @override
  void didUpdateWidget(TripSearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _shown = _page;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final docs = ref.watch(tripSearchDocsProvider(widget.tripId));
    return docs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AmaterasuColors.primary),
      ),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.searchError,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            AmaterasuButton.tertiary(
              key: const Key('search-retry'),
              onPressed: () =>
                  ref.invalidate(tripSearchDocsProvider(widget.tripId)),
              label: l10n.searchRetry,
            ),
          ],
        ),
      ),
      data: (all) {
        final found = <(TripSearchDoc, String)>[
          for (final d in all)
            if (tripSearchMatch([d.title, ...d.texts], widget.query)
                case final snippet?)
              (d, snippet),
        ];
        final counts = <TripSearchSection, int>{};
        for (final (d, _) in found) {
          counts[d.section] = (counts[d.section] ?? 0) + 1;
        }
        final section = counts.containsKey(_section) ? _section : null;
        final shown = [
          for (final r in found)
            if (section == null || r.$1.section == section) r,
        ];
        return ListView(
          key: const Key('search-results'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (counts.length > 1) ...[
              TripSectionChoices<TripSearchSection>(
                keyPrefix: 'search-section',
                values: [
                  for (final s in TripSearchSection.values)
                    if (counts.containsKey(s)) s,
                ],
                codeOf: (s) => s.name,
                labelOf: (s) =>
                    l10n.searchSectionCount(s.label(l10n), counts[s]!),
                iconOf: (s) => s.icon,
                selected: section,
                allowNone: true,
                onChanged: (s) => setState(() {
                  _section = s;
                  _shown = _page;
                }),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              shown.isEmpty
                  ? l10n.searchEmpty(widget.query)
                  : l10n.searchCount(shown.length),
              key: const Key('search-count'),
              style: const TextStyle(color: AmaterasuColors.textMuted),
            ),
            const SizedBox(height: 8),
            for (final (d, snippet) in shown.take(_shown))
              TripSearchResultTile(
                doc: d,
                snippet: snippet,
                onTap: () => widget.onOpen(d),
              ),
            if (shown.length > _shown)
              AmaterasuButton.tertiary(
                key: const Key('search-more'),
                onPressed: () => setState(() => _shown += _page),
                label: l10n.searchMore,
              ),
          ],
        );
      },
    );
  }
}
