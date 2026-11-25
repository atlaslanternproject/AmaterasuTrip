// Voce compatta dell'Itinerario: miniatura quadrata (icona della sezione,
// le foto arriveranno con i dati veri), titolo, ora, zona, chip di stato;
// matita e cestino (doppia conferma). "Previsto / fatto": la proposta è
// barrata e sotto c'è cosa si è fatto davvero.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/appearance/amaterasu_dates.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_edit_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_confirm.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_itinerary_item.dart';
import 'trip_itinerary_thumb.dart';

export 'trip_itinerary_thumb.dart';

class TripItineraryTile extends StatelessWidget {
  const TripItineraryTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TripItineraryItem item;
  final VoidCallback onEdit;

  /// Null when the user may not delete (only author or owner).
  final VoidCallback? onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmAmaterasuAction(
      context,
      title: l10n.itineraryDeleteTitle,
      body: l10n.itineraryDeleteBody(item.title),
      confirmLabel: l10n.itineraryDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
      keyPrefix: 'itinerary-delete',
    );
    if (ok) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final i = item;
    final changed = i.actual != null;
    final meta = [
      if (i.time != null) AmaterasuDates.time(context, i.time!),
      i.zone ?? l10n.itineraryNoZone,
      tripItinerarySectionLabel(l10n, i),
    ].join(' · ');
    return Container(
      key: Key('itinerary-item-${i.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AmaterasuColors.borderWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripItineraryThumb(icon: tripItineraryIcon(i)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.title,
                  style: TextStyle(
                    color: changed
                        ? AmaterasuColors.textMuted
                        : AmaterasuColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: changed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (changed)
                  Text(
                    l10n.itineraryActual(i.actual!),
                    key: Key('itinerary-actual-${i.id}'),
                    style: const TextStyle(color: AmaterasuColors.accentGold),
                  ),
                Text(
                  meta,
                  style: const TextStyle(
                    color: AmaterasuColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (i.status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TripSectionChip(
                      label: TripSectionLabels.status(i.status!, l10n),
                      color: TripSectionLabels.statusColor(i.status!),
                    ),
                  ),
              ],
            ),
          ),
          AmaterasuEditButton(
            key: Key('itinerary-edit-${i.id}'),
            onPressed: onEdit,
          ),
          if (onDelete != null)
            IconButton(
              key: Key('itinerary-delete-${i.id}'),
              tooltip: l10n.itineraryDelete,
              color: AmaterasuColors.accentErrorSoft,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }
}
