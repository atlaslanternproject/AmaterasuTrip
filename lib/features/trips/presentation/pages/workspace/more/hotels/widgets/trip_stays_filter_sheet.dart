// Foglio dei filtri degli alloggi con il pannello dei filtri condiviso:
// stato, tipo di alloggio, prossimi o passati, ordine per data. Le scelte si
// applicano subito; "Azzera" toglie tutti i filtri e tiene l'ordine.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_sheet.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_status.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stays_filter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_labels.dart';

Future<void> showTripStaysFilterSheet(
  BuildContext context, {
  required TripStaysFilter initial,
  required ValueChanged<TripStaysFilter> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  Set<T> toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
  return showAmaterasuFilterSheet<TripStaysFilter>(
    context,
    keyPrefix: 'stays',
    initial: initial,
    onChanged: onChanged,
    isActive: (f) => f.isActive,
    cleared: (f) => f.cleared(),
    groupsOf: (filter, update) => [
      AmaterasuFilterGroup(l10n.staysFilterWhen, [
        for (final (option, label) in [
          (TripStaysWhen.all, l10n.staysFilterAll),
          (TripStaysWhen.upcoming, l10n.staysFilterUpcoming),
          (TripStaysWhen.past, l10n.staysFilterPast),
        ])
          AmaterasuFilterOption(
            key: 'stays-when-${option.name}',
            label: label,
            selected: filter.when == option,
            onTap: () => update(filter.copyWith(when: option)),
          ),
      ]),
      AmaterasuFilterGroup(l10n.staysSectionStatus, [
        for (final status in TripStayStatus.values)
          AmaterasuFilterOption(
            key: 'stays-filter-status-${status.code}',
            label: TripStayLabels.status(status, l10n),
            selected: filter.statuses.contains(status),
            onTap: () => update(
              filter.copyWith(statuses: toggle(filter.statuses, status)),
            ),
          ),
      ]),
      AmaterasuFilterGroup(l10n.staysSectionType, [
        for (final type in TripStayType.values)
          AmaterasuFilterOption(
            key: 'stays-filter-type-${type.code}',
            label: TripStayLabels.type(type, l10n),
            selected: filter.types.contains(type),
            onTap: () =>
                update(filter.copyWith(types: toggle(filter.types, type))),
            icon: TripStayLabels.typeIcon(type),
          ),
      ]),
      AmaterasuFilterGroup(l10n.staysSortTitle, [
        for (final (sort, label) in [
          (TripStaysSort.checkInAsc, l10n.staysSortAsc),
          (TripStaysSort.checkInDesc, l10n.staysSortDesc),
        ])
          AmaterasuFilterOption(
            key: 'stays-sort-${sort.name}',
            label: label,
            selected: filter.sort == sort,
            onTap: () => update(filter.copyWith(sort: sort)),
          ),
      ]),
    ],
  );
}
