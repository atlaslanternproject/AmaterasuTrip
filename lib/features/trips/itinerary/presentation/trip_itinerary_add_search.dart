// "Cerca" del "+" dell'Itinerario: gli elementi esistenti di una sezione
// (catalogo letto con la Mappa), cercati per nome; quelli non ancora
// nell'itinerario per primi, gli altri con la scritta "Già
// nell'itinerario". Restituisce l'elemento scelto.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/core/widgets/inputs/amaterasu_text_field.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_ref.dart';
import 'trip_itinerary_add.dart';
import 'trip_itinerary_thumb.dart';

/// Elements of [section] matching [query]: not yet linked first, then by
/// name.
List<TripItineraryRef> tripItinerarySearch(
  List<TripItineraryRef> catalog,
  TripSearchSection section,
  String query,
  Set<String> linked,
) {
  final q = query.trim().toLowerCase();
  return catalog
      .where((c) => c.section == section)
      .where((c) => q.isEmpty || c.title.toLowerCase().contains(q))
      .toList()
    ..sort((a, b) {
      final used =
          (linked.contains(a.key) ? 1 : 0) - (linked.contains(b.key) ? 1 : 0);
      return used != 0
          ? used
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
}

Future<TripItineraryRef?> searchTripItineraryRef(
  BuildContext context, {
  required TripSearchSection section,
  required List<TripItineraryRef> catalog,
  required Set<String> linked,
}) => showAmaterasuSheet<TripItineraryRef>(
  context,
  builder: (_) => _Search(section: section, catalog: catalog, linked: linked),
);

class _Search extends StatefulWidget {
  const _Search({
    required this.section,
    required this.catalog,
    required this.linked,
  });

  final TripSearchSection section;
  final List<TripItineraryRef> catalog;
  final Set<String> linked;

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final found = tripItinerarySearch(
      widget.catalog,
      widget.section,
      _query,
      widget.linked,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tripItinerarySectionName(l10n, widget.section),
              style: const TextStyle(
                color: AmaterasuColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AmaterasuTextField(
              key: const Key('itinerary-search'),
              hintText: l10n.itinerarySearchHint,
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            if (found.isEmpty)
              Text(
                l10n.itinerarySearchNone,
                key: const Key('itinerary-search-none'),
                style: const TextStyle(color: AmaterasuColors.textSecondary),
              ),
            for (final c in found)
              ListTile(
                key: Key('itinerary-add-existing-${c.refId}'),
                contentPadding: EdgeInsets.zero,
                leading: TripItineraryThumb(icon: c.section.icon, size: 40),
                title: Text(
                  c.title,
                  style: const TextStyle(color: AmaterasuColors.textPrimary),
                ),
                subtitle: widget.linked.contains(c.key)
                    ? Text(
                        l10n.itineraryAlreadyIn,
                        style: const TextStyle(
                          color: AmaterasuColors.textMuted,
                        ),
                      )
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
  }
}
