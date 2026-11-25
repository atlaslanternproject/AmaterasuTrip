// Parte alta di Itinerario e Mappa: etichetta piccola "Bozza: dati di
// esempio, non si salva" (nessun banner), scelta della vista (chip comuni
// delle sezioni) e barra dei filtri condivisa.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_bar.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_draft_label.dart';
import 'trip_itinerary_view.dart';

export 'trip_draft_label.dart';

class TripItineraryTop extends StatelessWidget {
  const TripItineraryTop({
    super.key,
    required this.view,
    required this.onView,
    required this.activeFilters,
    required this.onFilters,
    required this.onClear,
  });

  final TripItineraryView? view;
  final ValueChanged<TripItineraryView>? onView;
  final int activeFilters;
  final VoidCallback onFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = this.view;
    final onView = this.onView;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TripDraftLabel(),
          const SizedBox(height: 8),
          if (view != null && onView != null)
            TripSectionChoices<TripItineraryView>(
              keyPrefix: 'itinerary-view',
              values: TripItineraryView.values,
              codeOf: (v) => v.name,
              labelOf: (v) => v.label(l10n),
              iconOf: (v) => v.icon,
              selected: view,
              onChanged: (v) => onView(v ?? view),
            ),
          AmaterasuFilterBar(
            keyPrefix: 'itinerary',
            activeCount: activeFilters,
            onOpen: onFilters,
            onClear: onClear,
            padding: const EdgeInsets.only(top: 6),
          ),
        ],
      ),
    );
  }
}
