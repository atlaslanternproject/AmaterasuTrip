// Vista "Linea del tempo" dell'Itinerario: tutti i giorni del viaggio in
// una lista unica, intestazione per giorno ("Giorno 2 · 12 apr", "Oggi") e
// dentro i gruppi per zona; avviso dei giorni senza voci in cima e, in
// fondo, il gruppo "Fuori dalle date".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_outside.dart';

String tripItineraryDayTitle(
  BuildContext context,
  List<DateTime> days,
  DateTime day,
) {
  final l10n = AppLocalizations.of(context)!;
  final title = l10n.itineraryDayTitle(
    days.indexOf(day) + 1,
    AmaterasuDates.day(context, day),
  );
  final today = TripItineraryLogic.dateOnly(DateTime.now());
  return day == today ? '$title · ${l10n.itineraryToday}' : title;
}

/// Notice of the trip days without items (unfiltered), or nothing.
class TripItineraryEmptyDays extends StatelessWidget {
  const TripItineraryEmptyDays({
    super.key,
    required this.all,
    required this.days,
  });

  final List<TripItineraryItem> all;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final empty = TripItineraryLogic.emptyDays(all, days);
    if (empty.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        l10n.itineraryEmptyDays(
          empty.map((d) => AmaterasuDates.day(context, d)).join(', '),
        ),
        key: const Key('itinerary-empty-days'),
        style: const TextStyle(color: AmaterasuColors.accentGold),
      ),
    );
  }
}

class TripItineraryTimeline extends StatelessWidget {
  const TripItineraryTimeline({
    super.key,
    required this.all,
    required this.shown,
    required this.days,
    required this.actions,
  });

  final List<TripItineraryItem> all, shown;
  final List<DateTime> days;
  final TripItineraryActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final withItems = [
      for (final d in days)
        if (TripItineraryLogic.ofDay(shown, d).isNotEmpty) d,
    ];
    final outside = TripItineraryLogic.outside(shown, days);
    return ListView(
      key: const Key('itinerary-timeline'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        TripItineraryEmptyDays(all: all, days: days),
        if (withItems.isEmpty && outside.isEmpty)
          Text(
            l10n.itineraryEmpty,
            style: const TextStyle(color: AmaterasuColors.textSecondary),
          ),
        for (final d in withItems) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              tripItineraryDayTitle(context, days, d),
              key: Key('itinerary-day-${days.indexOf(d) + 1}'),
              style: const TextStyle(
                color: AmaterasuColors.accentGold,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TripItineraryDayContent(
            items: TripItineraryLogic.ofDay(shown, d),
            actions: actions,
          ),
        ],
        TripItineraryOutside(items: outside, actions: actions),
      ],
    );
  }
}
