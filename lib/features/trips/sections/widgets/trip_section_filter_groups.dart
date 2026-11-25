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
  List<String> customCategories = const [],
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
  // Custom categories used by the items (Extra D), only when there are.
  if (customCategories.isNotEmpty)
    TripSectionFilterGroup(
      id: 'custom-category',
      title: l10n.sectionsFilterCustomCategory,
      options: [
        ('all', l10n.sectionsAll),
        for (final label in customCategories) (label, label),
      ],
      selected: customCategories.contains(filter.custom)
          ? filter.custom
          : 'all',
      onSelected: (v) => onChanged(filter.copyWith(custom: v)),
    ),
];

/// Custom categories used by [items], sorted, without repeats.
List<String> tripSectionUsedCategories<T>(
  Iterable<T> items,
  List<String> Function(T item) of,
) {
  final labels = {for (final item in items) ...of(item)}.toList();
  labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return labels;
}
