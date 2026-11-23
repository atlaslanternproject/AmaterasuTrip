// Viste compatte di un elemento di una sezione: card "Elenco" (foto o
// icona piccola, titolo, etichette, date) e riga "Dettagli" (una riga
// essenziale), entrambe con le azioni rapide sempre raggiungibili.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/widgets/amaterasu_place_photo_carousel.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'trip_section_entry.dart';

class TripSectionCompactCard extends StatelessWidget {
  const TripSectionCompactCard({
    super.key,
    required this.keyPrefix,
    required this.entry,
    required this.actions,
  });

  final String keyPrefix;
  final TripSectionEntry entry;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final muted = entry.inactive;
    return Container(
      key: Key('$keyPrefix-compact-${entry.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceSheet,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AmaterasuColors.borderAccent, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  child: Opacity(
                    opacity: muted ? 0.5 : 1,
                    child: AmaterasuPlacePhotoCarousel(
                      placeId: entry.photoPlaceId,
                      placeholderIcon: entry.icon,
                      keyPrefix: keyPrefix,
                      height: 72,
                      controls: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(entry, 16, 2),
                    if (entry.chips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: entry.chips),
                    ],
                    if (entry.highlight case final highlight?) ...[
                      const SizedBox(height: 6),
                      Text(
                        highlight,
                        style: const TextStyle(
                          color: AmaterasuColors.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      ),
    );
  }
}

class TripSectionDetailsRow extends StatelessWidget {
  const TripSectionDetailsRow({
    super.key,
    required this.keyPrefix,
    required this.entry,
    required this.actions,
    this.status,
  });

  final String keyPrefix;
  final TripSectionEntry entry;
  final Widget actions;

  /// Short colored status after the dates, e.g. ("Prenotato", green).
  final (String, Color)? status;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('$keyPrefix-row-${entry.id}'),
    padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
    decoration: BoxDecoration(
      color: AmaterasuColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AmaterasuColors.borderWarm),
    ),
    child: Row(
      children: [
        Icon(entry.icon, size: 20, color: AmaterasuColors.accentBudget),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(entry, 14, 1),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: entry.highlight ?? entry.subtitle ?? ''),
                    if (status case (final label, final color))
                      TextSpan(
                        text: ' · $label',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AmaterasuColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions,
      ],
    ),
  );
}

Widget _title(TripSectionEntry entry, double size, int lines) => Text(
  entry.title,
  maxLines: lines,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: entry.inactive
        ? AmaterasuColors.textMuted
        : AmaterasuColors.textCream,
    fontSize: size,
    fontWeight: FontWeight.w700,
    decoration: entry.inactive ? TextDecoration.lineThrough : null,
  ),
);
