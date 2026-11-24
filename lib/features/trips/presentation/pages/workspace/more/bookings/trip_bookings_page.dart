// Pagina Prenotazioni del viaggio (biglietti, ingressi, tour, escursioni):
// filtri per stato, categoria e data, viste Card/Elenco/Dettagli ricordate
// sul dispositivo, editor, biglietto QR a schermo intero, spesa collegata
// ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation.dart';
import 'package:amaterasutrip/features/trips/reservations/models/trip_reservation_category.dart';
import 'package:amaterasutrip/features/trips/reservations/providers/trip_reservations_provider.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_filter.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_expense_actions.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_filter_groups.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_reservation_editor.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'widgets/trip_reservation_entry.dart';
import 'widgets/trip_reservation_ticket.dart';

class TripBookingsPage extends ConsumerStatefulWidget {
  const TripBookingsPage({
    super.key,
    required this.tripId,
    this.launch,
    this.today,
  });

  final String tripId;
  final AmaterasuLaunch? launch;
  final DateTime? today;

  @override
  ConsumerState<TripBookingsPage> createState() => _TripBookingsPageState();
}

class _TripBookingsPageState extends ConsumerState<TripBookingsPage>
    with TripSectionViewMemory {
  var _filter = const TripSectionFilter();

  @override
  String get viewSection => 'reservations';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripReservationsStoreProvider).currentUid;

  Future<void> _edit([TripReservation? initial]) async {
    final store = ref.read(tripReservationsStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripReservationEditor(
        tripId: widget.tripId,
        authorUid: uid,
        memberNames: ref.read(tripStaysMemberNamesProvider(widget.tripId)),
        places: ref.read(amaterasuPlaceSearchProvider),
        defaultCurrency:
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
    final store = ref.watch(tripReservationsStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;

    return TripSectionScaffold<TripReservation>(
      tripId: tripId,
      keyPrefix: 'reservation',
      title: l10n.tripBookingsTitle,
      addLabel: l10n.reservationAdd,
      onAdd: _edit,
      items: ref.watch(tripReservationsProvider(tripId)),
      emptyIcon: Icons.confirmation_number_rounded,
      emptyText: l10n.reservationEmpty,
      body: (items) {
        final shown = _filter.apply(
          items,
          today: widget.today ?? DateTime.now(),
          dayOf: (r) => r.date,
          timeOf: (r) => r.time,
          statusOf: (r) => r.status.code,
          kindOf: (r) => r.category.code,
        );
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'reservation',
              onClear: () => setState(() => _filter = _filter.cleared()),
              shown: shown.length,
              total: items.length,
              groups: tripSectionFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
                statuses: [
                  for (final s in TripBookingStatus.values)
                    (s.code, TripSectionLabels.status(s, l10n)),
                ],
                kinds: [
                  for (final c in TripReservationCategory.values)
                    (c.code, TripReservationLabels.category(c, l10n)),
                ],
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripReservation>(
                keyPrefix: 'reservation',
                items: shown,
                view: view,
                header: [if (shown.isEmpty) Text(l10n.sectionsNoMatch)],
                entryOf: (r) => tripReservationEntry(
                  context,
                  r,
                  nameOf,
                  today: widget.today,
                ),
                extraOf: (r) => r.ticketCode == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: AmaterasuButton.secondary(
                          key: Key('reservation-ticket-${r.id}'),
                          icon: Icons.qr_code_2_rounded,
                          label: l10n.reservationShowTicket,
                          onPressed: () => showTripReservationTicket(
                            context,
                            r,
                            tripSectionWhen(context, r.date, r.time),
                          ),
                        ),
                      ),
                statusOf: (r) => (
                  TripSectionLabels.status(r.status, l10n),
                  TripSectionLabels.statusColor(r.status),
                ),
                onEdit: _edit,
                canDelete: (r) =>
                    uid != null && (uid == r.createdByUid || uid == ownerUid),
                onDelete: (r) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'reservation',
                  name: r.name,
                  delete: () => store.delete(r),
                ),
                api: ref.watch(tripStaysBudgetApiProvider(tripId)),
                expenseOf: (r) => TripSectionExpenseTarget(
                  keyPrefix: 'reservation',
                  id: r.id,
                  title: r.name,
                  category: 'activities',
                  date: r.date,
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
