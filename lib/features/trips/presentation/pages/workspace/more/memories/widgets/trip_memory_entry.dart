// Ricordi nelle viste: pagina di diario (giorno, stelle, momento del
// giorno, testo, autore) oppure album esterno (nome e link aperto con il
// modulo dei link).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_stars.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_chip.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_entry.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// "★★★★☆" for 4 of 5.

TripSectionEntry tripMemoryEntry(
  BuildContext context,
  TripMemory item,
  String Function(String uid) nameOf,
) {
  final l10n = AppLocalizations.of(context)!;
  final author = l10n.memoryWrittenBy(nameOf(item.createdByUid));
  if (item.isAlbum) {
    return TripSectionEntry(
      id: item.id,
      icon: Icons.photo_library_outlined,
      title: item.title ?? l10n.memoryAlbum,
      highlight: author,
      chips: [
        TripSectionChip(
          label: l10n.memoryAlbum,
          color: AmaterasuColors.accentGold,
          icon: Icons.photo_library_outlined,
        ),
      ],
      links: [
        if (item.url case final url?) (l10n.memoryOpenAlbum, url),
        ...TripSectionLabels.usefulLinks(item.usefulLinks, l10n),
      ],
    );
  }
  final date = item.date;
  final rating = item.rating;
  return TripSectionEntry(
    id: item.id,
    icon: Icons.auto_stories_outlined,
    title: date == null
        ? l10n.memoryDiary
        : MaterialLocalizations.of(context).formatFullDate(date),
    subtitle: item.moment,
    highlight: author,
    chips: [
      if (rating != null)
        TripSectionChip(
          label: tripSectionStars(rating),
          color: AmaterasuColors.accentGold,
        ),
    ],
    lines: [
      if (item.text case final text?)
        TripSectionLine(Icons.notes_outlined, text),
    ],
  );
}
