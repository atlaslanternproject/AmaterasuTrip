// Blocco "Visita" dell'editor di un luogo salvato: priorità SS/S/A/B come
// nella bucket list, visitato, giorno previsto, zona, tempo di visita,
// prezzo d'ingresso (selettore di valuta comune) e link dei biglietti.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_saved_place_draft.dart';

class TripSavedPlaceVisitBlock extends StatelessWidget {
  const TripSavedPlaceVisitBlock({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripSavedPlaceDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = draft;
    return TripSectionBlock(
      title: l10n.savedPlaceBlockVisit,
      icon: Icons.directions_walk_rounded,
      children: [
        Text(l10n.savedPlacePriority),
        const SizedBox(height: 6),
        TripSectionChoices<String>(
          keyPrefix: 'saved-place-priority',
          values: TripSavedPlaceCodec.priorities,
          codeOf: (p) => p,
          labelOf: (p) => p,
          selected: d.priority,
          allowNone: true,
          onChanged: (p) {
            d.priority = p;
            onChanged();
          },
        ),
        // Transparent material: the block already has its own background.
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            key: const Key('saved-place-visited'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.savedPlaceVisited),
            value: d.visited,
            onChanged: (v) {
              d.visited = v;
              onChanged();
            },
          ),
        ),
        TripSectionDayButton(
          fieldKey: 'saved-place-day',
          label: l10n.savedPlaceDay,
          value: d.plannedDay,
          onChanged: (v) {
            d.plannedDay = v;
            onChanged();
          },
          onClear: () {
            d.plannedDay = null;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('saved-place-area'),
          controller: d.area,
          maxLength: TripSectionFields.shortMax,
          decoration: InputDecoration(
            labelText: l10n.savedPlaceArea,
            helperText: l10n.savedPlaceAreaHint,
          ),
        ),
        TextField(
          key: const Key('saved-place-minutes'),
          controller: d.minutes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 4,
          decoration: InputDecoration(labelText: l10n.savedPlaceMinutes),
        ),
        TripSectionCostField(
          keyPrefix: 'saved-place',
          draft: d.price,
          label: l10n.savedPlaceEntryPrice,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('saved-place-tickets'),
          controller: d.tickets,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.savedPlaceTickets),
        ),
      ],
    );
  }
}
