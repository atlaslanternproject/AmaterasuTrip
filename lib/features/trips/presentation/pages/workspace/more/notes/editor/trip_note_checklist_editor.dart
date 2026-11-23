// Checklist nell'editor di una nota: una riga per voce con casella, testo
// e pulsante per toglierla, più "Aggiungi voce". Le voci vuote non si
// salvano.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note_codec.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripNoteChecklistDraft {
  TripNoteChecklistDraft(List<TripChecklistItem>? initial)
    : rows = [
        for (final item in initial ?? const <TripChecklistItem>[])
          (TextEditingController(text: item.text), item.done),
      ];

  final List<(TextEditingController, bool)> rows;

  List<TripChecklistItem> items() => [
    for (final (text, done) in rows)
      if (text.text.trim().isNotEmpty) TripChecklistItem(text.text, done: done),
  ];

  void dispose() {
    for (final (text, _) in rows) {
      text.dispose();
    }
  }
}

class TripNoteChecklistEditor extends StatelessWidget {
  const TripNoteChecklistEditor({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripNoteChecklistDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = draft.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, (text, done)) in rows.indexed)
          Row(
            children: [
              Checkbox(
                value: done,
                activeColor: AmaterasuColors.accentBudget,
                onChanged: (v) {
                  rows[index] = (text, v ?? false);
                  onChanged();
                },
              ),
              Expanded(
                child: TextField(
                  key: Key('note-item-$index'),
                  controller: text,
                  maxLength: TripNoteCodec.itemMax,
                  decoration: InputDecoration(
                    hintText: l10n.noteItemHint,
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.sectionsClear,
                onPressed: () {
                  rows.removeAt(index);
                  onChanged();
                },
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AmaterasuColors.textSecondary,
                ),
              ),
            ],
          ),
        if (rows.length < TripNoteCodec.checklistMax)
          TextButton.icon(
            key: const Key('note-item-add'),
            onPressed: () {
              rows.add((TextEditingController(), false));
              onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.noteItemAdd),
          ),
      ],
    );
  }
}
