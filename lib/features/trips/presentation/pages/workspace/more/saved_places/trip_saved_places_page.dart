// Pagina Luoghi salvati del viaggio: filtri per categoria e visitato,
// ordine per priorità o nome, raggruppamento per zona o giorno, tre viste
// ricordate, "Orari e prezzi" di Google su richiesta, editor ed
// eliminazione (creatore o OWNER). Nessuna spesa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place.dart';
import 'package:amaterasutrip/features/trips/saved_places/models/trip_saved_place_category.dart';
import 'package:amaterasutrip/features/trips/saved_places/providers/trip_saved_places_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_priority.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_hours_sheet.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_saved_place_editor.dart';
import 'widgets/trip_saved_place_entry.dart';

part 'trip_saved_places_page_filters.dart';

class TripSavedPlacesPage extends ConsumerStatefulWidget {
  const TripSavedPlacesPage({super.key, required this.tripId, this.launch});

  final String tripId;
  final AmaterasuLaunch? launch;

  @override
  ConsumerState<TripSavedPlacesPage> createState() =>
      _TripSavedPlacesPageState();
}

class _TripSavedPlacesPageState extends ConsumerState<TripSavedPlacesPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();
  var _visited = 'all';
  var _sort = 'priority';

  @override
  String get viewSection => 'savedPlaces';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripSavedPlacesStoreProvider).currentUid;

  Future<void> _edit([TripSavedPlace? initial]) async {
    final store = ref.read(tripSavedPlacesStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripSavedPlaceEditor(
        tripId: widget.tripId,
        authorUid: uid,
        places: ref.read(amaterasuPlaceSearchProvider),
        placeInfo: ref.read(amaterasuPlaceInfoProvider),
        currency:
            ref.read(tripStaysTripInfoProvider(widget.tripId))?.currency ??
            'EUR',
        initial: initial,
        onSave: (item) =>
            initial == null ? store.create(item) : store.update(item),
      ),
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sectionsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = widget.tripId;
    final store = ref.watch(tripSavedPlacesStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;
    final currency =
        ref.watch(tripStaysTripInfoProvider(tripId))?.currency ?? 'EUR';

    return TripSectionScaffold<TripSavedPlace>(
      tripId: tripId,
      keyPrefix: 'saved-place',
      title: l10n.tripSavedPlacesTitle,
      addLabel: l10n.savedPlaceAdd,
      onAdd: _edit,
      items: ref.watch(tripSavedPlacesProvider(tripId)),
      emptyIcon: Icons.bookmark_rounded,
      emptyText: l10n.savedPlaceEmpty,
      body: (items) {
        final shown = _sorted(items);
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'saved-place',
              onClear: () => setState(() {
                _filter = _filter.cleared();
                _visited = 'all';
              }),
              shown: shown.length,
              total: items.length,
              groups: _groups(l10n),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripSavedPlace>(
                keyPrefix: 'saved-place',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (p) => tripSavedPlaceEntry(context, p, nameOf),
                groupOf: _groupOf(context),
                extraOf: (p) => p.place.placeId == null
                    ? null
                    : TripSectionHoursButton(
                        target: TripSectionHoursTarget(
                          keyPrefix: 'saved-place',
                          id: p.id,
                          placeId: p.place.placeId!,
                          tripCurrency: currency,
                          day: p.plannedDay,
                        ),
                      ),
                onEdit: _edit,
                canDelete: (p) =>
                    uid != null && (uid == p.createdByUid || uid == ownerUid),
                onDelete: (p) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'saved-place',
                  name: p.name,
                  delete: () => store.delete(p),
                ),
                launch: widget.launch,
              ),
            ),
          ],
        );
      },
    );
  }
}
