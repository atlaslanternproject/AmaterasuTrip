// Pagina Itinerario (dati veri, trips/{tripId}/itinerary): le voci scelte
// dall'utente, con i dati aggiornati degli elementi collegati (catalogo
// letto con la Mappa); viste ricordate (la prima volta secondo la fase del
// viaggio), filtri, aggiungi, modifica; elimina solo autore o proprietario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_appearance_provider.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_icon_button.dart';
import 'package:amaterasutrip/features/trips/map/trip_map_sources.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_segments.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_recent.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../data/trip_itinerary_repository.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_add.dart';
import 'trip_itinerary_body.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_editor.dart';
import 'trip_itinerary_filters.dart';
import 'trip_itinerary_view.dart';

class TripItineraryScreen extends ConsumerStatefulWidget {
  const TripItineraryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripItineraryScreen> createState() => _State();
}

class _State extends ConsumerState<TripItineraryScreen> {
  final _filters = ValueNotifier(const TripItineraryFilters());

  /// Null until the user chooses (decision 6: then remembered).
  TripItineraryView? _view;
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

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.sectionsSaveError;
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(tripItineraryRepositoryProvider);
    final trip = ref.watch(tripProvider(widget.tripId)).asData?.value;
    // Only the trip days (decision 12): none while loading or undated.
    final days =
        trip == null || TripItineraryLogic.undated(trip.startDate, trip.endDate)
        ? const <DateTime>[]
        : TripItineraryLogic.days(trip.startDate, trip.endDate);
    final names = ref.watch(tripStaysMemberNamesProvider(widget.tripId));
    final catalog =
        ref.watch(tripMapDataProvider(widget.tripId)).asData?.value.catalog ??
        const [];
    final live = {for (final c in catalog) '${c.section.name}/${c.refId}': c};
    final saved =
        ref.watch(tripItineraryItemsProvider(widget.tripId)).asData?.value ??
        const <TripItineraryItem>[];
    // Linked items always show the current data of their element.
    final all = [
      for (final i in saved)
        live['${i.section?.name}/${i.refId}']?.applyTo(i) ?? i,
    ];
    final f = _filters.value;
    final today = TripItineraryLogic.dateOnly(DateTime.now());
    final view =
        _view ??
        (days.contains(today)
            ? TripItineraryView.day
            : TripItineraryView.timeline);
    Future<void> add() => _run(() async {
      final item = await addTripItineraryItem(
        context,
        day: f.day ?? (days.contains(today) ? today : days.first),
        days: days,
        tripId: widget.tripId,
        uid: _uid ?? '',
        catalog: catalog,
        linked: {for (final i in saved) '${i.section?.name}/${i.refId}'},
      );
      if (item != null) await repo.save(item);
    });
    final actions = TripItineraryActions(
      units: ref.watch(amaterasuAppearanceProvider).units,
      canDelete: (i) => i.createdByUid == _uid || trip?.ownerUid == _uid,
      onEdit: (i) => _run(() async {
        final changed = await editTripItineraryItem(
          context,
          item: i,
          days: days,
        );
        if (changed != null) await repo.save(changed);
      }),
      onDelete: (i) => _run(() => repo.delete(i)),
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
              actions: [
                IconButton(
                  key: const Key('itinerary-refresh'),
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
                    days: view == TripItineraryView.map ? days : const [],
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
                  onPressed: days.isEmpty ? null : add,
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
                selected: view,
                onChanged: _setView,
                compact: true,
              ),
            ),
            Expanded(
              child: TripItineraryBody(
                tripId: widget.tripId,
                loading: trip == null,
                view: view,
                all: all,
                shown: all.where(f.matches).toList(),
                days: days,
                actions: actions,
                filtered: f.count > 0,
                onAdd: add,
                onReorder: (items) => _run(() => repo.reorder(items)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
