// Card grande di un elemento di una sezione, nello stile delle card degli
// alloggi e della bucket list: foto Google facoltativa, icona, titolo,
// sottotitolo, date evidenziate, etichette, dettagli, link e azioni.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:amaterasutrip/core/links/amaterasu_link_opener.dart';
import 'package:amaterasutrip/core/places/widgets/amaterasu_place_photo_carousel.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_edit_button.dart';
import 'trip_section_card_parts.dart';
import 'trip_section_entry.dart';

class TripSectionCard extends StatelessWidget {
  const TripSectionCard({
    super.key,
    required this.keyPrefix,
    required this.entry,
    required this.actions,
    this.footer,
    this.launch,
    this.onEdit,
  });

  final String keyPrefix;
  final TripSectionEntry entry;

  /// Map, contact, edit and delete (TripSectionQuickActions).
  final Widget actions;

  /// Linked expense or other content at the bottom.
  final Widget? footer;
  final AmaterasuLaunch? launch;

  /// Pencil at the top of the card.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final muted = entry.inactive;
    return Container(
      key: Key('$keyPrefix-card-${entry.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceSheet,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmaterasuColors.borderAccent, width: 1.6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.photoPlaceId != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: muted ? 0.5 : 1,
                    child: AmaterasuPlacePhotoCarousel(
                      placeId: entry.photoPlaceId,
                      placeholderIcon: entry.icon,
                      keyPrefix: keyPrefix,
                      height: wide ? 200 : 150,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TripSectionCardBadge(icon: entry.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Titles(entry: entry, wide: wide),
                  ),
                  if (onEdit != null)
                    AmaterasuEditButton(
                      key: Key('$keyPrefix-edit-${entry.id}'),
                      onPressed: onEdit,
                    ),
                ],
              ),
              if (entry.chips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 7, runSpacing: 7, children: entry.chips),
              ],
              for (final line in entry.lines) TripSectionCardLine(line),
              if (entry.links.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final (label, url) in entry.links)
                      AmaterasuLinkChip(
                        link: url,
                        label: label,
                        launch: launch,
                      ),
                  ],
                ),
              ],
              ?footer,
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.entry, required this.wide});

  final TripSectionEntry entry;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final muted = entry.inactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          style: TextStyle(
            color: muted
                ? AmaterasuColors.textMuted
                : AmaterasuColors.textCream,
            fontSize: wide ? 20 : 18,
            fontWeight: FontWeight.w700,
            height: 1.15,
            decoration: muted ? TextDecoration.lineThrough : null,
          ),
        ),
        if (entry.subtitle case final subtitle?) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AmaterasuColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        if (entry.highlight case final highlight?) ...[
          const SizedBox(height: 4),
          Text(
            highlight,
            style: const TextStyle(
              color: AmaterasuColors.accentGold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
