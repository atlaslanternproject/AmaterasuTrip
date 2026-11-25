// Vista "Giorno per giorno": striscia dei giorni in alto (scelto oggi, o il
// primo giorno se il viaggio è nel futuro), contenuto del giorno con i
// gruppi per zona, "Riordina" (solo senza filtri) e "Condividi il giorno".

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import '../models/trip_itinerary_logic.dart';
import 'trip_itinerary_day_content.dart';
import 'trip_itinerary_reorder.dart';
import 'trip_itinerary_share.dart';
import 'trip_itinerary_timeline.dart';

/// Today when inside the trip, otherwise the first day.
DateTime tripItineraryStartDay(List<DateTime> days, DateTime now) {
  final today = TripItineraryLogic.dateOnly(now);
  return days.contains(today) ? today : days.first;
}

class TripItineraryDayView extends StatefulWidget {
  const TripItineraryDayView({
    super.key,
    required this.all,
    required this.shown,
    required this.days,
    required this.actions,
    required this.filtered,
    required this.onReorder,
  });

  final List<TripItineraryItem> all, shown;
  final List<DateTime> days;
  final TripItineraryActions actions;

  /// Filters are active: reordering is off.
  final bool filtered;
  final ValueChanged<List<String>> onReorder;

  @override
  State<TripItineraryDayView> createState() => _TripItineraryDayViewState();
}

class _TripItineraryDayViewState extends State<TripItineraryDayView> {
  late DateTime _day = tripItineraryStartDay(widget.days, DateTime.now());
  bool _reordering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = TripItineraryLogic.ofDay(widget.shown, _day);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            key: const Key('itinerary-day-strip'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (n, d) in widget.days.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('itinerary-strip-${n + 1}'),
                    label: Text(AmaterasuDates.day(context, d)),
                    selected: d == _day,
                    selectedColor: AmaterasuColors.accentBudget.withValues(
                      alpha: 0.25,
                    ),
                    onSelected: (_) => setState(() {
                      _day = d;
                      _reordering = false;
                    }),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                tripItineraryDayTitle(context, widget.days, _day),
                style: const TextStyle(
                  color: AmaterasuColors.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AmaterasuButton.tertiary(
                key: const Key('itinerary-reorder'),
                icon: Icons.swap_vert_rounded,
                label: _reordering
                    ? l10n.itineraryReorderDone
                    : l10n.itineraryReorder,
                onPressed: widget.filtered || items.length < 2
                    ? null
                    : () => setState(() => _reordering = !_reordering),
              ),
              AmaterasuButton.tertiary(
                key: const Key('itinerary-share'),
                icon: Icons.ios_share_rounded,
                label: l10n.itineraryShare,
                onPressed: items.isEmpty
                    ? null
                    : () => tripItineraryShareDay(context, _day, items),
              ),
            ],
          ),
        ),
        if (widget.filtered)
          Text(
            l10n.itineraryReorderFilters,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 12,
            ),
          ),
        Expanded(
          child: _reordering
              ? TripItineraryReorderList(items: items, onDone: widget.onReorder)
              : ListView(
                  key: const Key('itinerary-day-list'),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    TripItineraryEmptyDays(all: widget.all, days: widget.days),
                    if (items.isEmpty)
                      Text(
                        l10n.itineraryEmpty,
                        style: const TextStyle(
                          color: AmaterasuColors.textSecondary,
                        ),
                      )
                    else
                      TripItineraryDayContent(
                        items: items,
                        actions: widget.actions,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
