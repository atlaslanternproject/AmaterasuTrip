// "Aggiungi voce" dell'Itinerario: voce libera, giornata libera oppure da
// un elemento esistente (elenco degli elementi delle sezioni); poi lo
// stesso editor. Nella bozza la voce nuova resta solo in memoria.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_editor.dart';
import 'trip_itinerary_tile.dart';

Future<TripItineraryItem?> addTripItineraryItem(
  BuildContext context, {
  required DateTime day,
  required List<DateTime> days,
  required List<TripItineraryItem> catalog,
  String? personUid,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final id = 'new-${DateTime.now().microsecondsSinceEpoch}';
  final start = await showAmaterasuSheet<TripItineraryItem>(
    context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.itineraryAdd,
              style: const TextStyle(
                color: AmaterasuColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final (key, kind, label, icon) in [
              (
                'free',
                TripItineraryKind.free,
                l10n.itineraryAddFree,
                Icons.edit_note_rounded,
              ),
              (
                'free-day',
                TripItineraryKind.freeDay,
                l10n.itineraryAddFreeDay,
                Icons.wb_sunny_outlined,
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AmaterasuButton.secondary(
                  key: Key('itinerary-add-$key'),
                  icon: icon,
                  label: label,
                  onPressed: () => Navigator.pop(
                    sheet,
                    TripItineraryItem(
                      id: id,
                      day: day,
                      kind: kind,
                      title: kind == TripItineraryKind.freeDay
                          ? l10n.itineraryFreeDay
                          : '',
                      personUid: personUid,
                    ),
                  ),
                ),
              ),
            Text(
              l10n.itineraryAddExisting,
              style: const TextStyle(color: AmaterasuColors.textSecondary),
            ),
            for (final c in catalog)
              ListTile(
                key: Key('itinerary-add-existing-${c.id}'),
                contentPadding: EdgeInsets.zero,
                leading: TripItineraryThumb(
                  icon: tripItineraryIcon(c),
                  size: 40,
                ),
                title: Text(
                  c.title,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                subtitle: Text(
                  tripItinerarySectionLabel(l10n, c),
                  style: const TextStyle(color: AmaterasuColors.textMuted),
                ),
                onTap: () => Navigator.pop(
                  sheet,
                  TripItineraryItem(
                    id: id,
                    day: day,
                    kind: TripItineraryKind.ref,
                    title: c.title,
                    section: c.section,
                    refId: c.refId,
                    place: c.place,
                    status: c.status,
                    personUid: personUid ?? c.personUid,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (start == null || !context.mounted) return null;
  return editTripItineraryItem(context, item: start, days: days);
}
