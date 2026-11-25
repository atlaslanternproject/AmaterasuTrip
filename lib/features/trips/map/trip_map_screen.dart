// Pagina Mappa (solo lettura): TUTTI gli elementi con posizione di ogni
// sezione del viaggio, letti una volta all'apertura ("Aggiorna" rilegge);
// filtri condivisi (sezione, giorno, stato, persona): con un giorno scelto
// gli elementi senza giorno restano visibili ma attenuati.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/common/amaterasu_loader.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_icon_button.dart';
import 'package:amaterasutrip/features/trips/itinerary/models/trip_itinerary_logic.dart';
import 'package:amaterasutrip/features/trips/itinerary/presentation/trip_itinerary_filters.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_map_sources.dart';
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
    final data = ref.watch(tripMapDataProvider(widget.tripId));
    final trip = ref.watch(tripProvider(widget.tripId)).asData?.value;
    final days = trip == null
        ? const <DateTime>[]
        : TripItineraryLogic.days(trip.startDate, trip.endDate);
    final names = ref.watch(tripStaysMemberNamesProvider(widget.tripId));
    final f = _filters.value;
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(
              tripId: widget.tripId,
              title: l10n.tripMapTitle,
              actions: [
                IconButton(
                  key: const Key('map-refresh'),
                  tooltip: l10n.searchRefresh,
                  icon: const Icon(
                    Icons.refresh,
                    color: AmaterasuColors.textPrimary,
                  ),
                  onPressed: () =>
                      ref.invalidate(tripMapDataProvider(widget.tripId)),
                ),
                AmaterasuFilterIconButton(
                  keyPrefix: 'itinerary',
                  activeCount: f.count,
                  onPressed: () => showTripItineraryFilters(
                    context,
                    filters: _filters,
                    names: names,
                    days: days,
                    onChanged: (v) => setState(() => _filters.value = v),
                  ),
                ),
              ],
            ),
            Expanded(
              child: data.when(
                loading: () => const Center(child: AmaterasuLoader()),
                error: (_, _) => Center(
                  child: TextButton(
                    key: const Key('map-retry'),
                    onPressed: () =>
                        ref.invalidate(tripMapDataProvider(widget.tripId)),
                    child: Text('${l10n.mapError} ${l10n.mapRetry}'),
                  ),
                ),
                data: (d) {
                  final shown = [
                    for (final p in d.points)
                      if (f.matchesPoint(p)) p,
                  ];
                  return TripMapView(
                    tripId: widget.tripId,
                    points: shown,
                    routes: tripMapRoutes(shown),
                    dimmed: {
                      if (f.day != null)
                        for (final p in shown)
                          if (p.day == null) p.id,
                    },
                    withoutPosition: d.withoutPosition,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
