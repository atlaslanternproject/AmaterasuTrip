// Pagina Trasporti del viaggio: elenco con filtri (stato, tipo, prossimi o
// passati, ordine), viste Card/Elenco/Dettagli ricordate sul dispositivo,
// avvisi di coincidenze strette, editor, spesa collegata ed eliminazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_delete.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_expense_actions.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_list.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_scaffold.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transports_filter.dart';
import 'package:amaterasutrip/features/trips/transports/providers/trip_transports_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'editor/trip_transport_editor.dart';
import 'widgets/trip_transport_entry.dart';
import 'widgets/trip_transport_filters.dart';
import 'widgets/trip_transport_labels.dart';
import 'widgets/trip_transport_warnings.dart';

class TripTransportPage extends ConsumerStatefulWidget {
  const TripTransportPage({
    super.key,
    required this.tripId,
    this.launch,
    this.today,
  });

  final String tripId;
  final AmaterasuLaunch? launch;

  /// "Today" for the upcoming / past filter; tests set it.
  final DateTime? today;

  @override
  ConsumerState<TripTransportPage> createState() => _TripTransportPageState();
}

class _TripTransportPageState extends ConsumerState<TripTransportPage>
    with TripSectionViewMemory {
  var _filter = const TripTransportsFilter();

  @override
  String get viewSection => 'transports';
  @override
  String get viewTripId => widget.tripId;
  @override
  String? get viewUid => ref.read(tripTransportsStoreProvider).currentUid;

  Future<void> _edit([TripTransport? initial]) async {
    final store = ref.read(tripTransportsStoreProvider);
    final uid = store.currentUid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showTripSectionEditor(
      context,
      TripTransportEditor(
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
    final store = ref.watch(tripTransportsStoreProvider);
    final uid = store.currentUid;
    final ownerUid = ref.watch(tripStaysOwnerUidProvider(tripId));
    final names = ref.watch(tripStaysMemberNamesProvider(tripId));
    final api = ref.watch(tripStaysBudgetApiProvider(tripId));
    String nameOf(String id) => names[id] ?? l10n.sectionsFormerMember;

    return TripSectionScaffold<TripTransport>(
      tripId: tripId,
      keyPrefix: 'transport',
      title: l10n.tripTransportTitle,
      addLabel: l10n.transportAdd,
      onAdd: _edit,
      items: ref.watch(tripTransportsProvider(tripId)),
      emptyIcon: Icons.train_rounded,
      emptyText: l10n.transportEmpty,
      body: (items) {
        final shown = _filter.apply(items, widget.today ?? DateTime.now());
        return Column(
          children: [
            TripSectionToolbar(
              keyPrefix: 'transport',
              groups: tripTransportFilterGroups(
                l10n,
                _filter,
                (f) => setState(() => _filter = f),
              ),
              view: view,
              onView: changeView,
            ),
            Expanded(
              child: TripSectionList<TripTransport>(
                keyPrefix: 'transport',
                items: shown,
                view: view,
                header: [
                  TripTransportWarnings(items: items),
                  if (shown.isEmpty) Text(l10n.sectionsNoMatch),
                ],
                entryOf: (item) => tripTransportEntry(context, item, nameOf),
                statusOf: (item) => (
                  TripSectionLabels.status(item.status, l10n),
                  TripSectionLabels.statusColor(item.status),
                ),
                onEdit: _edit,
                canDelete: (item) =>
                    uid != null &&
                    (uid == item.createdByUid || uid == ownerUid),
                onDelete: (item) => confirmTripSectionDelete(
                  context,
                  keyPrefix: 'transport',
                  name: TripTransportLabels.title(item, l10n),
                  delete: () => store.delete(item),
                ),
                api: api,
                expenseOf: (item) => TripSectionExpenseTarget(
                  keyPrefix: 'transport',
                  id: item.id,
                  title: TripTransportLabels.title(item, l10n),
                  category: 'transport',
                  date: item.departureDate,
                  minorUnits: item.estimatedCostMinorUnits,
                  currency: item.estimatedCostCurrency,
                  expenseId: item.expenseId,
                  link: (expenseId) => store.linkExpense(item, expenseId),
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
