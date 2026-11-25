// Editor di una nota nella cornice comune delle sezioni: titolo, testo con
// formattazione di base, privata (solo l'autore può cambiarlo), fissata in
// alto, collegamento a un elemento del viaggio, checklist, modelli pronti
// (Info utili, Frasi utili, Contatti) per le note nuove.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note.dart';
import 'package:amaterasutrip/features/trips/notes/models/trip_note_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_note_checklist_editor.dart';
import 'trip_note_link_field.dart';
import 'trip_note_text_tools.dart';

class TripNoteEditor extends StatefulWidget {
  const TripNoteEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Future<void> Function(TripNote note) onSave;
  final TripNote? initial;

  @override
  State<TripNoteEditor> createState() => _TripNoteEditorState();
}

class _TripNoteEditorState extends State<TripNoteEditor>
    with TripSectionEditorSave {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  late var _private = widget.initial?.isPrivate ?? false;
  late var _pinned = widget.initial?.pinned ?? false;
  late final _items = TripNoteChecklistDraft(widget.initial?.checklist);
  late TripNoteLink? _link = widget.initial?.link;

  /// Only the author may change who can read the note.
  bool get _canChangePrivacy =>
      widget.initial == null ||
      widget.initial!.createdByUid == widget.authorUid;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _items.dispose();
    super.dispose();
  }

  void _useTemplate(String title, String body) => setState(() {
    _title.text = title;
    _body.text = body;
    _pinned = true;
  });

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final initial = widget.initial;
    final note = TripNote(
      id: initial?.id ?? '',
      tripId: widget.tripId,
      createdByUid: initial?.createdByUid ?? widget.authorUid,
      title: _title.text.trim(),
      body: TripSectionFields.clean(_body.text),
      isPrivate: _private,
      pinned: _pinned,
      checklist: _items.items(),
      link: _link,
    );
    return saveWith(
      problems: [
        for (final p in const TripNoteCodec().problems(note))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.noteTitle,
            other: (_) => l10n.noteErrChecklist,
          ),
      ],
      save: () => widget.onSave(note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionEditorFrame(
      keyPrefix: 'note',
      title: widget.initial == null
          ? l10n.noteEditorNewTitle
          : l10n.noteEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.noteBlockText,
          icon: Icons.sticky_note_2_outlined,
          children: [
            if (widget.initial == null) TripNoteTemplates(onPick: _useTemplate),
            TextField(
              key: const Key('note-title'),
              controller: _title,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.noteTitle),
            ),
            TripNoteFormatBar(controller: _body),
            TextField(
              key: const Key('note-body'),
              controller: _body,
              minLines: 3,
              maxLines: 10,
              maxLength: TripSectionFields.notesMax,
              decoration: InputDecoration(labelText: l10n.noteBody),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('note-private'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AmaterasuColors.accentBudget,
                value: _private,
                onChanged: _canChangePrivacy
                    ? (v) => setState(() => _private = v)
                    : null,
                title: Text(l10n.notePrivateSwitch),
                subtitle: Text(l10n.notePrivateHint),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('note-pinned'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AmaterasuColors.accentBudget,
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
                title: Text(l10n.notePinnedSwitch),
              ),
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.noteBlockLink,
          icon: Icons.link_rounded,
          children: [
            TripNoteLinkField(
              tripId: widget.tripId,
              link: _link,
              onChanged: (link) => setState(() => _link = link),
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.noteBlockChecklist,
          icon: Icons.checklist_rounded,
          children: [
            TripNoteChecklistEditor(
              draft: _items,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ],
    );
  }
}
