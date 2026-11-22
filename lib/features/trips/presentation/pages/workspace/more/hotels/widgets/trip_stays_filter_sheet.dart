// Foglio dei filtri degli alloggi: stato, tipo di alloggio, prossimi o
// passati, ordine per data. Le scelte si applicano subito; "Azzera"
// toglie tutti i filtri e tiene l'ordine.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
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
  var filter = initial;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AmaterasuColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        void update(TripStaysFilter next) {
          setState(() => filter = next);
          onChanged(next);
        }

        Set<T> toggle<T>(Set<T> set, T value) =>
            set.contains(value) ? ({...set}..remove(value)) : {...set, value};

        Widget chip(
          String key,
          String label,
          bool selected,
          VoidCallback onTap, {
          IconData? icon,
        }) => FilterChip(
          key: Key(key),
          avatar: icon == null
              ? null
              : Icon(icon, size: 16, color: AmaterasuColors.accentBudget),
          label: Text(label),
          selected: selected,
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (_) => onTap(),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.staysFilters,
                        style: const TextStyle(
                          color: AmaterasuColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('stays-sheet-clear'),
                      onPressed: filter.isActive
                          ? () => update(filter.cleared())
                          : null,
                      child: Text(l10n.staysFiltersClear),
                    ),
                  ],
                ),
                _Title(l10n.staysFilterWhen),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final (option, label) in [
                      (TripStaysWhen.all, l10n.staysFilterAll),
                      (TripStaysWhen.upcoming, l10n.staysFilterUpcoming),
                      (TripStaysWhen.past, l10n.staysFilterPast),
                    ])
                      chip(
                        'stays-when-${option.name}',
                        label,
                        filter.when == option,
                        () => update(filter.copyWith(when: option)),
                      ),
                  ],
                ),
                _Title(l10n.staysSectionStatus),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final status in TripStayStatus.values)
                      chip(
                        'stays-filter-status-${status.code}',
                        TripStayLabels.status(status, l10n),
                        filter.statuses.contains(status),
                        () => update(
                          filter.copyWith(
                            statuses: toggle(filter.statuses, status),
                          ),
                        ),
                      ),
                  ],
                ),
                _Title(l10n.staysSectionType),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final type in TripStayType.values)
                      chip(
                        'stays-filter-type-${type.code}',
                        TripStayLabels.type(type, l10n),
                        filter.types.contains(type),
                        () => update(
                          filter.copyWith(types: toggle(filter.types, type)),
                        ),
                        icon: TripStayLabels.typeIcon(type),
                      ),
                  ],
                ),
                _Title(l10n.staysSortTitle),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final (sort, label) in [
                      (TripStaysSort.checkInAsc, l10n.staysSortAsc),
                      (TripStaysSort.checkInDesc, l10n.staysSortDesc),
                    ])
                      chip(
                        'stays-sort-${sort.name}',
                        label,
                        filter.sort == sort,
                        () => update(filter.copyWith(sort: sort)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('stays-sheet-done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AmaterasuColors.accentBudget,
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.staysFiltersDone),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AmaterasuColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
