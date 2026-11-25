// Filtri di Itinerario e Mappa con il pannello condiviso dei filtri
// (showAmaterasuFilterSheet): sezione (o voce libera), persona, stato e,
// nella Mappa, giorno. Un valore nullo vuol dire "tutti".

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_sheet.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_booking_status.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/tools/search/trip_search_sources.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';

class TripItineraryFilters {
  const TripItineraryFilters({
    this.section,
    this.person,
    this.status,
    this.day,
  });

  /// A TripSearchSection name, or "free" for free items and free days.
  final String? section;
  final String? person;
  final TripBookingStatus? status;
  final DateTime? day;

  int get count =>
      [section, person, status, day].where((v) => v != null).length;

  bool matches(TripItineraryItem i) =>
      (section == null || (i.section?.name ?? 'free') == section) &&
      (person == null || i.personUid == person) &&
      (status == null || i.status == status) &&
      (day == null ||
          TripItineraryLogic.dateOnly(i.day) ==
              TripItineraryLogic.dateOnly(day!));

  TripItineraryFilters copy({
    String? Function()? section,
    String? Function()? person,
    TripBookingStatus? Function()? status,
    DateTime? Function()? day,
  }) => TripItineraryFilters(
    section: section == null ? this.section : section(),
    person: person == null ? this.person : person(),
    status: status == null ? this.status : status(),
    day: day == null ? this.day : day(),
  );
}

Future<void> showTripItineraryFilters(
  BuildContext context, {
  required ValueListenable<TripItineraryFilters> filters,
  required Map<String, String> names,
  required ValueChanged<TripItineraryFilters> onChanged,
  List<DateTime> days = const [],
}) {
  final l10n = AppLocalizations.of(context)!;
  AmaterasuFilterGroup group<T>(
    String id,
    String title,
    T? selected,
    List<(T?, String)> options,
    TripItineraryFilters Function(T?) apply,
    ValueChanged<TripItineraryFilters> update,
  ) => AmaterasuFilterGroup(title, [
    for (final (value, label) in options)
      AmaterasuFilterOption(
        key:
            'itinerary-filter-$id-${value is DateTime ? value.day : value ?? 'all'}',
        label: label,
        selected: selected == value,
        onTap: () => update(apply(value)),
      ),
  ]);
  return showAmaterasuFilterSheet<TripItineraryFilters>(
    context,
    keyPrefix: 'itinerary',
    initial: filters.value,
    listenable: filters,
    onChanged: onChanged,
    isActive: (f) => f.count > 0,
    cleared: (_) => const TripItineraryFilters(),
    groupsOf: (f, update) => [
      group<String>(
        'section',
        l10n.itineraryFilterSection,
        f.section,
        [
          (null, l10n.itineraryAll),
          for (final s in [
            TripSearchSection.stays,
            TripSearchSection.transports,
            TripSearchSection.reservations,
            TripSearchSection.restaurants,
            TripSearchSection.savedPlaces,
            TripSearchSection.bucketList,
          ])
            (s.name, s.label(l10n)),
          ('free', l10n.itineraryFreeItem),
        ],
        (v) => f.copy(section: () => v),
        update,
      ),
      group<String>(
        'person',
        l10n.itineraryFilterPerson,
        f.person,
        [
          (null, l10n.itineraryAll),
          for (final e in names.entries) (e.key, e.value),
        ],
        (v) => f.copy(person: () => v),
        update,
      ),
      group<TripBookingStatus>(
        'status',
        l10n.itineraryFilterStatus,
        f.status,
        [
          (null, l10n.itineraryAll),
          for (final s in [TripBookingStatus.booked, TripBookingStatus.toBook])
            (s, TripSectionLabels.status(s, l10n)),
        ],
        (v) => f.copy(status: () => v),
        update,
      ),
      if (days.isNotEmpty)
        group<DateTime>(
          'day',
          l10n.itineraryFilterDay,
          f.day,
          [
            (null, l10n.itineraryAll),
            for (final d in days) (d, AmaterasuDates.day(context, d)),
          ],
          (v) => f.copy(day: () => v),
          update,
        ),
    ],
  );
}
