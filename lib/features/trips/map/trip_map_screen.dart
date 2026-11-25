// Pagina Mappa (bozza): TUTTE le cose con posizione di ogni sezione, non
// solo l'itinerario (nella bozza: voci di esempio più elementi non in
// programma), filtri condivisi (sezione, giorno, stato, persona), linee
// tratteggiate per giorno e riquadro al tocco. Nulla si salva.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/itinerary/data/trip_itinerary_repository.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_filters.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_top.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_point.dart';
import 'trip_map_view.dart';

class TripMapScreen extends ConsumerStatefulWidget {
  const TripMapScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  final _filters = ValueNotifier(const TripItineraryFilters());

  @override
  void dispose() {
    _filters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(tripItineraryRepositoryProvider);
    final info = repo.info(widget.tripId);
    final days = TripItineraryLogic.days(info.start, info.end);
    final items =
        ref.watch(tripItineraryItemsProvider(widget.tripId)).asData?.value ??
        const [];
    final f = _filters.value;
    final planned = {for (final i in items) i.refId};
    // Elements not in the itinerary have no day: hidden by a day filter.
    final others = [
      for (final c in info.catalog)
        if (!planned.contains(c.refId) && f.day == null) c,
    ];
    final shown = items.where(f.matches).toList();
    final points = tripMapPoints([...shown, ...others.where(f.matches)]);
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: widget.tripId, title: l10n.tripMapTitle),
            TripItineraryTop(
              view: null,
              onView: null,
              activeFilters: f.count,
              onFilters: () => showTripItineraryFilters(
                context,
                filters: _filters,
                names: info.names,
                days: days,
                onChanged: (v) => setState(() => _filters.value = v),
              ),
              onClear: () =>
                  setState(() => _filters.value = const TripItineraryFilters()),
            ),
            Expanded(
              child: TripMapView(
                tripId: widget.tripId,
                points: points,
                routes: tripMapRoutes(shown),
                unscheduled: {for (final o in others) o.id},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
