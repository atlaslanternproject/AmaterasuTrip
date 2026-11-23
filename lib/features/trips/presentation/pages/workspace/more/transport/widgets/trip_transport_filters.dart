// Gruppi di filtri della pagina Trasporti per la barra comune delle
// sezioni: stato, tipo, prossimi/passati e ordine per partenza.

import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_toolbar.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transport_type.dart';
import 'package:amaterasutrip/features/trips/transports/models/trip_transports_filter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_transport_labels.dart';

List<TripSectionFilterGroup> tripTransportFilterGroups(
  AppLocalizations l10n,
  TripTransportsFilter filter,
  void Function(TripTransportsFilter filter) onChanged,
) => [
  TripSectionFilterGroup(
    id: 'status',
    options: [
      ('all', l10n.sectionsAll),
      for (final s in TripBookingStatus.values)
        (s.code, TripSectionLabels.status(s, l10n)),
    ],
    selected: filter.status,
    onSelected: (v) => onChanged(filter.copyWith(status: v)),
  ),
  TripSectionFilterGroup(
    id: 'type',
    options: [
      ('all', l10n.sectionsAll),
      for (final t in TripTransportType.values)
        (t.code, TripTransportLabels.type(t, l10n)),
    ],
    selected: filter.type,
    onSelected: (v) => onChanged(filter.copyWith(type: v)),
  ),
  TripSectionFilterGroup(
    id: 'when',
    options: [
      ('all', l10n.sectionsAll),
      ('upcoming', l10n.sectionsUpcoming),
      ('past', l10n.sectionsPast),
    ],
    selected: filter.when,
    onSelected: (v) => onChanged(filter.copyWith(when: v)),
  ),
  TripSectionFilterGroup(
    id: 'sort',
    options: [
      ('first', l10n.sectionsSortFirst),
      ('last', l10n.sectionsSortLast),
    ],
    selected: filter.latestFirst ? 'last' : 'first',
    onSelected: (v) => onChanged(filter.copyWith(latestFirst: v == 'last')),
  ),
];
