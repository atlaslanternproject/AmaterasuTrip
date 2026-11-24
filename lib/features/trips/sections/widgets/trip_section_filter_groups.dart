// Gruppi di filtri comuni per la barra delle sezioni: stato, categoria,
// prossimi/passati e ordine, ciascuno facoltativo.

import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_section_filter.dart';
import 'trip_section_toolbar.dart';

List<TripSectionFilterGroup> tripSectionFilterGroups(
  AppLocalizations l10n,
  TripSectionFilter filter,
  void Function(TripSectionFilter filter) onChanged, {
  List<(String, String)>? statuses,
  List<(String, String)>? kinds,
  String? kindTitle,
  bool dated = true,
}) => [
  if (statuses != null)
    TripSectionFilterGroup(
      id: 'status',
      title: l10n.sectionsBlockStatus,
      options: [('all', l10n.sectionsAll), ...statuses],
      selected: filter.status,
      onSelected: (v) => onChanged(filter.copyWith(status: v)),
    ),
  if (kinds != null)
    TripSectionFilterGroup(
      id: 'kind',
      title: kindTitle ?? l10n.sectionsFilterCategory,
      options: [('all', l10n.sectionsAll), ...kinds],
      selected: filter.kind,
      onSelected: (v) => onChanged(filter.copyWith(kind: v)),
    ),
  if (dated) ...[
    TripSectionFilterGroup(
      id: 'when',
      title: l10n.sectionsFilterWhen,
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
      title: l10n.filtersSort,
      isSort: true,
      options: [
        ('first', l10n.sectionsSortFirst),
        ('last', l10n.sectionsSortLast),
      ],
      selected: filter.latestFirst ? 'last' : 'first',
      onSelected: (v) => onChanged(filter.copyWith(latestFirst: v == 'last')),
    ),
  ],
];
