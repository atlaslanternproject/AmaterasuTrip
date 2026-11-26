// Elenco degli elementi senza posizione della Mappa (si apre toccando il
// contatore): icona e nome della sezione, nome dell'elemento; un tocco
// porta alla sezione. Nessuna lettura in più: sono già nel catalogo.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_ref.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_thumb.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> showTripMapMissing(
  BuildContext context, {
  required String tripId,
  required List<TripItineraryRef> missing,
}) {
  final l10n = AppLocalizations.of(context)!;
  final sorted = [...missing]
    ..sort((a, b) {
      final s = a.section.index.compareTo(b.section.index);
      return s != 0 ? s : a.title.compareTo(b.title);
    });
  return showAmaterasuSheet<void>(
    context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('map-missing'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mapMissingTitle,
              style: const TextStyle(
                color: AmaterasuColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mapMissingHint,
              style: const TextStyle(
                color: AmaterasuColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in sorted)
              ListTile(
                key: Key('map-missing-${r.section.name}-${r.refId}'),
                contentPadding: EdgeInsets.zero,
                leading: TripItineraryThumb(icon: r.section.icon, size: 40),
                title: Text(
                  r.title,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                subtitle: Text(
                  r.section.label(l10n),
                  style: const TextStyle(color: AmaterasuColors.textMuted),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AmaterasuColors.textMuted,
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  context.go(r.section.route(tripId, r.refId));
                },
              ),
          ],
        ),
      ),
    ),
  );
}
