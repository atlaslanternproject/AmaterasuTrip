// Pagina Itinerario (bozza): voci dal repository (demo in memoria), tre
// viste con la scelta ricordata, filtri condivisi, "Aggiungi voce",
// modifica ed eliminazione. Nulla si salva su Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_icon_button.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_segments.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_recent.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_point.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_view.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../data/trip_itinerary_repository.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_add.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_day_view.dart';
import 'trip_itinerary_editor.dart';
import 'trip_itinerary_filters.dart';
import 'trip_itinerary_timeline.dart';
import 'trip_draft_label.dart';
import 'trip_itinerary_view.dart';

class TripItineraryScreen extends ConsumerStatefulWidget {
  const TripItineraryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripItineraryScreen> createState() => _State();
}

class _State extends ConsumerState<TripItineraryScreen> {
  final _filters = ValueNotifier(const TripItineraryFilters());
  TripItineraryView _view = TripItineraryView.timeline;
  late final String? _uid = ref.read(tripSearchUidProvider);

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid != null) {
      TripItineraryViewPreferences.load(uid, widget.tripId).then((v) {
        if (v != null && mounted) setState(() => _view = v);
      });
    }
  }

  @override
  void dispose() {
    _filters.dispose();
    super.dispose();
  }

  void _setView(TripItineraryView v) {
    setState(() => _view = v);
    if (_uid != null) TripItineraryViewPreferences.save(_uid, widget.tripId, v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(tripItineraryRepositoryProvider);
    final info = repo.info(widget.tripId);
    final days = TripItineraryLogic.days(info.start, info.end);
    final all =
        ref.watch(tripItineraryItemsProvider(widget.tripId)).asData?.value ??
        const [];
    final f = _filters.value;
    final shown = all.where(f.matches).toList();
    final actions = TripItineraryActions(
      units: ref.watch(amaterasuAppearanceProvider).units,
      onEdit: (i) async {
        final changed = await editTripItineraryItem(
          context,
          item: i,
          days: days,
        );
        if (changed != null) await repo.save(widget.tripId, changed);
      },
      onDelete: (i) => repo.delete(widget.tripId, i.id),
    );
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(
              tripId: widget.tripId,
              title: l10n.tripNavItinerary,
              backRoute: '/trips/${widget.tripId}',
              subtitle: const TripDraftLabel(),
              actions: [
                IconButton(
                  key: const Key('itinerary-refresh'),
                  tooltip: l10n.searchRefresh,
                  icon: const Icon(
                    Icons.refresh,
                    color: AmaterasuColors.textPrimary,
                  ),
                  onPressed: () =>
                      ref.invalidate(tripItineraryItemsProvider(widget.tripId)),
                ),
                AmaterasuFilterIconButton(
                  keyPrefix: 'itinerary',
                  activeCount: f.count,
                  onPressed: () => showTripItineraryFilters(
                    context,
                    filters: _filters,
                    names: info.names,
                    days: _view == TripItineraryView.map ? days : const [],
                    onChanged: (v) => setState(() => _filters.value = v),
                  ),
                ),
                IconButton(
                  key: const Key('itinerary-add'),
                  tooltip: l10n.itineraryAdd,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AmaterasuColors.accentOrange,
                  ),
                  onPressed: () async {
                    final item = await addTripItineraryItem(
                      context,
                      day: f.day ?? days.first,
                      days: days,
                      catalog: info.catalog,
                      personUid: _uid,
                    );
                    if (item != null) await repo.save(widget.tripId, item);
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TripSectionSegments<TripItineraryView>(
                keyPrefix: 'itinerary',
                values: TripItineraryView.values,
                codeOf: (v) => v.name,
                labelOf: (v) => v.label(l10n),
                iconOf: (v) => v.icon,
                selected: _view,
                onChanged: _setView,
                compact: true,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _view == TripItineraryView.map
                        ? double.infinity
                        : 820,
                  ),
                  child: switch (_view) {
                    TripItineraryView.timeline => TripItineraryTimeline(
                      all: all,
                      shown: shown,
                      days: days,
                      actions: actions,
                    ),
                    TripItineraryView.day => TripItineraryDayView(
                      all: all,
                      shown: shown,
                      days: days,
                      actions: actions,
                      filtered: f.count > 0,
                      onReorder: (ids) => repo.reorder(widget.tripId, ids),
                    ),
                    TripItineraryView.map => TripMapView(
                      tripId: widget.tripId,
                      points: tripMapPoints(shown),
                      routes: tripMapRoutes(shown),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
