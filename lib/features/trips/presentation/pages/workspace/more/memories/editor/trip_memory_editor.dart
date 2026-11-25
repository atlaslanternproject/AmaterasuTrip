// Editor di un ricordo nella cornice comune delle sezioni: pagina di diario
// (giorno, valutazione, momento del giorno, testo) oppure album esterno
// (nome e link). Nessuna foto viene caricata.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_stars.dart';

import 'package:amaterasutrip/features/trips/memories/models/trip_memory.dart';
import 'package:amaterasutrip/features/trips/memories/models/trip_memory_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_pickers.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripMemoryEditor extends StatefulWidget {
  const TripMemoryEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.onSave,
    this.initial,
    this.today,
  });

  final String tripId;
  final String authorUid;
  final Future<void> Function(TripMemory item) onSave;
  final TripMemory? initial;
  final DateTime? today;

  @override
  State<TripMemoryEditor> createState() => _TripMemoryEditorState();
}

class _TripMemoryEditorState extends State<TripMemoryEditor>
    with TripSectionEditorSave {
  late final _i = widget.initial;
  late var _kind = _i?.kind ?? TripMemoryKind.day;
  late DateTime? _date =
      _i?.date ?? DateUtils.dateOnly(widget.today ?? DateTime.now());
  late int? _rating = _i?.rating;
  late final _moment = TextEditingController(text: _i?.moment);
  late final _text = TextEditingController(text: _i?.text);
  late final _title = TextEditingController(text: _i?.title);
  late final _url = TextEditingController(text: _i?.url);

  @override
  void dispose() {
    for (final c in [_moment, _text, _title, _url]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final album = _kind == TripMemoryKind.album;
    String? clean(TextEditingController c) => TripSectionFields.clean(c.text);
    final item = TripMemory(
      id: _i?.id ?? '',
      tripId: widget.tripId,
      createdByUid: _i?.createdByUid ?? widget.authorUid,
      kind: _kind,
      date: album ? null : _date,
      rating: album ? null : _rating,
      moment: album ? null : clean(_moment),
      text: album ? null : clean(_text),
      title: album ? clean(_title) : null,
      url: album ? clean(_url) : null,
    );
    return saveWith(
      problems: [
        for (final p in const TripMemoryCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (f) =>
                f == 'url' ? l10n.memoryAlbumLink : l10n.memoryAlbumName,
            other: (_) => l10n.memoryErrDate,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  Widget _field(
    String key,
    TextEditingController c,
    String label,
    int max, {
    int lines = 1,
  }) => TextField(
    key: Key('memory-$key'),
    controller: c,
    maxLength: max,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 6,
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final album = _kind == TripMemoryKind.album;
    return TripSectionEditorFrame(
      keyPrefix: 'memory',
      title: _i == null
          ? l10n.memoryEditorNewTitle
          : l10n.memoryEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.memoryBlockKind,
          icon: Icons.auto_stories_outlined,
          children: [
            TripSectionChoices<TripMemoryKind>(
              keyPrefix: 'memory-kind',
              values: TripMemoryKind.values,
              codeOf: (k) => k.name,
              labelOf: (k) => k == TripMemoryKind.album
                  ? l10n.memoryAlbum
                  : l10n.memoryDiary,
              selected: _kind,
              onChanged: (k) => setState(() => _kind = k ?? _kind),
            ),
          ],
        ),
        if (album)
          TripSectionBlock(
            title: l10n.memoryAlbum,
            icon: Icons.photo_library_outlined,
            children: [
              _field('title', _title, l10n.memoryAlbumName, 200),
              _field('url', _url, l10n.memoryAlbumLink, 2048),
              Text(l10n.memoryAlbumHint),
            ],
          )
        else
          TripSectionBlock(
            title: l10n.memoryDiary,
            icon: Icons.edit_note_rounded,
            children: [
              TripSectionDayButton(
                fieldKey: 'memory-day',
                label: l10n.memoryDay,
                value: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 8),
              Text(l10n.memoryRating),
              TripSectionChoices<int>(
                keyPrefix: 'memory-rating',
                values: const [1, 2, 3, 4, 5],
                codeOf: (r) => '$r',
                labelOf: tripSectionStars,
                selected: _rating,
                allowNone: true,
                onChanged: (r) => setState(() => _rating = r),
              ),
              _field('moment', _moment, l10n.memoryMoment, 300),
              _field('text', _text, l10n.memoryText, 10000, lines: 4),
            ],
          ),
      ],
    );
  }
}
