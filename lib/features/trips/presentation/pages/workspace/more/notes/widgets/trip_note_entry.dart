// Note nelle viste: icona (fissata, privata o normale), titolo, etichette
// Privata/Condivisa e Fissata, testo formattato, elemento collegato,
// avanzamento della checklist; nella card grande le voci della checklist
// si spuntano direttamente. Qui anche nomi e icone delle sezioni collegabili.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

abstract final class TripNoteLabels {
  static String section(String code, AppLocalizations l10n) => switch (code) {
    'stays' => l10n.tripHotelsTitle,
    'transports' => l10n.tripTransportTitle,
    'reservations' => l10n.tripBookingsTitle,
    'restaurants' => l10n.tripRestaurantsTitle,
    _ => l10n.tripSavedPlacesTitle,
  };

  static IconData sectionIcon(String code) => switch (code) {
    'stays' => Icons.hotel_outlined,
    'transports' => Icons.flight_takeoff_rounded,
    'reservations' => Icons.confirmation_number_outlined,
    'restaurants' => Icons.restaurant_outlined,
    _ => Icons.bookmark_outline_rounded,
  };
}

TripSectionEntry tripNoteEntry(BuildContext context, TripNote note) {
  final l10n = AppLocalizations.of(context)!;
  final total = note.checklist.length;
  return TripSectionEntry(
    id: note.id,
    icon: note.pinned
        ? Icons.push_pin_rounded
        : (note.isPrivate
              ? Icons.lock_outline_rounded
              : Icons.sticky_note_2_outlined),
    title: note.title,
    highlight: total == 0
        ? null
        : l10n.noteChecklistProgress(note.doneCount, total),
    chips: [
      TripSectionChip(
        label: note.isPrivate ? l10n.notePrivate : l10n.noteShared,
        color: note.isPrivate
            ? AmaterasuColors.accentGold
            : AmaterasuColors.textSecondary,
        icon: note.isPrivate
            ? Icons.lock_outline_rounded
            : Icons.group_outlined,
      ),
      if (note.pinned)
        TripSectionChip(
          label: l10n.notePinned,
          color: AmaterasuColors.accentBudget,
          icon: Icons.push_pin_outlined,
        ),
      for (final label in note.customCategories)
        TripSectionChip(
          label: label,
          color: AmaterasuColors.textSecondary,
          icon: Icons.label_outline_rounded,
        ),
    ],
    lines: [
      if (note.link case final link?)
        TripSectionLine(
          TripNoteLabels.sectionIcon(link.section),
          l10n.noteLinkedTo(
            link.name,
            TripNoteLabels.section(link.section, l10n),
          ),
          key: Key('note-linked-${note.id}'),
        ),
      if (note.body case final body?)
        TripSectionLine(Icons.notes_outlined, body, formatted: true),
    ],
    links: TripSectionLabels.usefulLinks(note.usefulLinks, l10n),
  );
}

/// Checklist of a note with tappable boxes (big card only).
class TripNoteChecklist extends StatelessWidget {
  const TripNoteChecklist({
    super.key,
    required this.note,
    required this.onToggle,
  });

  final TripNote note;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    if (note.checklist.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      // Transparent Material so the tiles paint their ink inside the card.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final (index, item) in note.checklist.indexed)
              CheckboxListTile(
                key: Key('note-check-${note.id}-$index'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AmaterasuColors.accentBudget,
                value: item.done,
                onChanged: (_) => onToggle(index),
                title: Text(
                  item.text,
                  style: TextStyle(
                    color: item.done
                        ? AmaterasuColors.textMuted
                        : AmaterasuColors.textPrimary,
                    fontSize: 14,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
