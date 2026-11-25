// Pagina Ristoranti del viaggio: filtri per stato e fascia di prezzo,
// ordine per voti, nome o prenotazione, tre viste ricordate, voti dei
// viaggiatori nella card, "Orari e prezzi" di Google su richiesta, editor,
// spesa collegata ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_entry_currency.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_status.dart';
import 'package:amaterasutrip/features/trips/restaurants/models/trip_restaurant_votes.dart';
import 'package:amaterasutrip/features/trips/restaurants/providers/trip_restaurants_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_expense_actions.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_hours_sheet.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_restaurant_editor.dart';
import 'widgets/trip_restaurant_entry.dart';
import 'widgets/trip_restaurant_votes_bar.dart';

part 'trip_restaurants_page_filters.dart';

class TripRestaurantsPage extends ConsumerStatefulWidget {
  const TripRestaurantsPage({super.key, required this.tripId, this.launch});

  final String tripId;
  final AmaterasuLaunch? launch;

  @override
  ConsumerState<TripRestaurantsPage> createState() =>
      _TripRestaurantsPageState();
}

class _TripRestaurantsPageState extends ConsumerState<TripRestaurantsPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();
  var _sort = 'votes';

  /// 'all', 'yes' (allergens to tell) or 'no'.
  var _allergens = 'all';

  @override
  String get viewSection => 'restaurants';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripRestaurantsStoreProvider).currentUid;

  Future<void> _edit([TripRestaurant? initial]) async {
    final store = ref.read(tripRestaurantsStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripRestaurantEditor(
        tripId: widget.tripId,
        authorUid: uid,
        places: ref.read(amaterasuPlaceSearchProvider),
        placeInfo: ref.read(amaterasuPlaceInfoProvider),
        defaultCurrency:
            amaterasuDefaultEntryCurrency(context) ??
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
    final store = ref.watch(tripRestaurantsStoreProvider);
    final votes = ref.watch(tripRestaurantVotesProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final messenger = ScaffoldMessenger.of(context);
    final currency =
        ref.watch(tripStaysTripInfoProvider(tripId))?.currency ?? 'EUR';

    return TripSectionScaffold<TripRestaurant>(
      tripId: tripId,
      keyPrefix: 'restaurant',
      title: l10n.tripRestaurantsTitle,
      addLabel: l10n.restaurantAdd,
      onAdd: _edit,
      items: ref.watch(tripRestaurantsProvider(tripId)),
      emptyIcon: Icons.restaurant_rounded,
      emptyText: l10n.restaurantEmpty,
      body: (items) {
        final shown = _sorted(items);
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'restaurant',
              onClear: () => setState(() {
                _filter = _filter.cleared();
                _allergens = 'all';
              }),
              shown: shown.length,
              total: items.length,
              groups: _groups(l10n, items),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripRestaurant>(
                keyPrefix: 'restaurant',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (r) => tripRestaurantEntry(context, r),
                statusOf: (r) => (
                  TripRestaurantLabels.status(r.status, l10n),
                  TripRestaurantLabels.color(r.status),
                ),
                extraOf: (r) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.place.placeId != null)
                      TripSectionHoursButton(
                        target: TripSectionHoursTarget(
                          keyPrefix: 'restaurant',
                          id: r.id,
                          placeId: r.place.placeId!,
                          tripCurrency: currency,
                          day: r.reservationDate,
                          time: r.reservationTime,
                        ),
                      ),
                    TripRestaurantVotesBar(
                      item: r,
                      uid: uid,
                      onVote: (level) => votes
                          .vote(
                            tripId: tripId,
                            restaurantId: r.id,
                            uid: uid!,
                            level: level,
                          )
                          .catchError(
                            (_) => messenger.showSnackBar(
                              SnackBar(content: Text(l10n.sectionsSaveError)),
                            ),
                          ),
                    ),
                  ],
                ),
                onEdit: _edit,
                canDelete: (r) =>
                    uid != null && (uid == r.createdByUid || uid == ownerUid),
                onDelete: (r) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'restaurant',
                  name: r.name,
                  delete: () => store.delete(r),
                ),
                api: ref.watch(tripStaysBudgetApiProvider(tripId)),
                expenseOf: (r) => TripSectionExpenseTarget(
                  keyPrefix: 'restaurant',
                  id: r.id,
                  title: r.name,
                  category: 'food',
                  date: r.reservationDate,
                  minorUnits: r.estimatedCostMinorUnits,
                  currency: r.estimatedCostCurrency,
                  expenseId: r.expenseId,
                  link: (expenseId) => store.linkExpense(r, expenseId),
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
