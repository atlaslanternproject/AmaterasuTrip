// "Aggiungi voce" dell'Itinerario (decisione 13): prima si sceglie cosa
// aggiungere (voce libera, giornata libera o una sezione); per una sezione
// si cerca tra i suoi elementi ("Nuovo" arriva al passo 3). Poi lo stesso
// editor con giorno e ora facoltativa; l'autore è chi aggiunge.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../data/trip_itinerary_codec.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_ref.dart';
import 'trip_itinerary_add_search.dart';
import 'trip_itinerary_editor.dart';

/// Singular name of a section in the "+" choice.
String tripItinerarySectionName(AppLocalizations l10n, TripSearchSection s) =>
    switch (s) {
      TripSearchSection.stays => l10n.itineraryKindStay,
      TripSearchSection.transports => l10n.itineraryKindTransport,
      TripSearchSection.reservations => l10n.itineraryKindReservation,
      TripSearchSection.restaurants => l10n.itineraryKindRestaurant,
      TripSearchSection.savedPlaces => l10n.itineraryKindSavedPlace,
      _ => l10n.itineraryKindBucket,
    };

Future<TripItineraryItem?> addTripItineraryItem(
  BuildContext context, {
  required DateTime day,
  required List<DateTime> days,
  required String tripId,
  required String uid,
  required List<TripItineraryRef> catalog,
  required Set<String> linked,
}) async {
  final l10n = AppLocalizations.of(context)!;
  TripItineraryItem free(TripItineraryKind kind) => TripItineraryItem(
    tripId: tripId,
    createdByUid: uid,
    day: day,
    kind: kind,
    title: kind == TripItineraryKind.freeDay ? l10n.itineraryFreeDay : '',
  );
  Widget choice(String key, IconData icon, String label, Object value) =>
      Builder(
        builder: (sheet) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AmaterasuButton.secondary(
            key: Key('itinerary-add-$key'),
            icon: icon,
            label: label,
            onPressed: () => Navigator.pop(sheet, value),
          ),
        ),
      );
  final picked = await showAmaterasuSheet<Object>(
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
            choice(
              'free',
              Icons.edit_note_rounded,
              l10n.itineraryAddFree,
              TripItineraryKind.free,
            ),
            choice(
              'free-day',
              Icons.wb_sunny_outlined,
              l10n.itineraryAddFreeDay,
              TripItineraryKind.freeDay,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                l10n.itineraryAddExisting,
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
            ),
            for (final s in tripItineraryRefSections)
              choice(
                'section-${s.name}',
                s.icon,
                tripItinerarySectionName(l10n, s),
                s,
              ),
          ],
        ),
      ),
    ),
  );
  if (picked == null || !context.mounted) return null;
  final TripItineraryItem? start;
  if (picked is TripItineraryKind) {
    start = free(picked);
  } else {
    final ref = await searchTripItineraryRef(
      context,
      section: picked as TripSearchSection,
      catalog: catalog,
      linked: linked,
    );
    start = ref?.newItem(tripId: tripId, uid: uid, day: day);
  }
  if (start == null || !context.mounted) return null;
  return editTripItineraryItem(context, item: start, days: days);
}
