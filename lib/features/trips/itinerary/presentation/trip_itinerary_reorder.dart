// Riordino a mano delle voci senza ora di un giorno (trascina): per
// spostare una voce con ora si cambia l'ora. Il nuovo ordine si salva
// subito (campo order, scritture firmate).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_tile.dart';

class TripItineraryReorderList extends StatefulWidget {
  const TripItineraryReorderList({
    super.key,
    required this.items,
    required this.onDone,
  });

  final List<TripItineraryItem> items;
  final ValueChanged<List<TripItineraryItem>> onDone;

  @override
  State<TripItineraryReorderList> createState() =>
      _TripItineraryReorderListState();
}

class _TripItineraryReorderListState extends State<TripItineraryReorderList> {
  // Only items without a time are reordered (decision 1).
  late final List<TripItineraryItem> _order = [
    for (final i in widget.items)
      if (i.time == null) i,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            l10n.itineraryReorderHint,
            style: const TextStyle(
              color: AmaterasuColors.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            key: const Key('itinerary-reorder-list'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            // The new index already accounts for the removed item.
            onReorderItem: (from, to) {
              setState(() => _order.insert(to, _order.removeAt(from)));
              widget.onDone(List.of(_order));
            },
            children: [
              for (final i in _order)
                ListTile(
                  key: Key('itinerary-reorder-${i.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: TripItineraryThumb(
                    icon: tripItineraryIcon(i),
                    size: 40,
                  ),
                  title: Text(
                    i.title,
                    style: const TextStyle(color: AmaterasuColors.textPrimary),
                  ),
                  trailing: const Icon(
                    Icons.drag_handle_rounded,
                    color: AmaterasuColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
