// Sezioni "Ospiti" (viaggiatori che dormono nell'alloggio, anche ex
// viaggiatori già scelti) e "Note" dell'editor degli alloggi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayGuestsSection extends StatelessWidget {
  const TripStayGuestsSection({
    super.key,
    required this.draft,
    required this.memberNames,
    required this.onChanged,
  });

  final TripStayDraft draft;

  /// Current travelers: uid -> name.
  final Map<String, String> memberNames;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uids = {...memberNames.keys, ...draft.guestUids}.toList()
      ..sort(
        (a, b) => (memberNames[a] ?? '~').compareTo(memberNames[b] ?? '~'),
      );
    return TripStayEditorSection(
      title: l10n.staysSectionGuests,
      icon: Icons.people_outline,
      children: [
        Text(l10n.staysGuestsHint, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final uid in uids)
              FilterChip(
                key: Key('stay-guest-$uid'),
                label: Text(memberNames[uid] ?? l10n.staysFormerGuest),
                selected: draft.guestUids.contains(uid),
                onSelected: (selected) {
                  selected
                      ? draft.guestUids.add(uid)
                      : draft.guestUids.remove(uid);
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

class TripStayNotesSection extends StatelessWidget {
  const TripStayNotesSection({super.key, required this.draft});

  final TripStayDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripStayEditorSection(
      title: l10n.staysSectionNotes,
      icon: Icons.notes_outlined,
      children: [
        TextField(
          key: const Key('stay-notes'),
          controller: draft.notes,
          minLines: 2,
          maxLines: 6,
          maxLength: TripStayValidator.notesMax,
          decoration: InputDecoration(labelText: l10n.staysNotes),
        ),
      ],
    );
  }
}
