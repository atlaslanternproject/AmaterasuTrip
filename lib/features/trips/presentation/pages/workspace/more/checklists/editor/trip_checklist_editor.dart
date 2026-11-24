// Editor di una checklist nella cornice comune delle sezioni: in creazione
// si sceglie il modello pronto (Valigia, Documenti…), poi titolo e se è
// condivisa o personale (lo cambia solo chi l'ha creata).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_templates.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripChecklistEditor extends StatefulWidget {
  const TripChecklistEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Future<void> Function(TripChecklist list) onSave;
  final TripChecklist? initial;

  @override
  State<TripChecklistEditor> createState() => _TripChecklistEditorState();
}

class _TripChecklistEditorState extends State<TripChecklistEditor>
    with TripSectionEditorSave {
  late final _title = TextEditingController(text: widget.initial?.title);
  late var _private = widget.initial?.isPrivate ?? false;
  String _template = 'packing';

  bool get _canChangePrivacy =>
      widget.initial == null ||
      widget.initial!.createdByUid == widget.authorUid;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final initial = widget.initial;
    final templates = TripChecklistTemplates.all(l10n);
    final template = templates.firstWhere((t) => t.code == _template);
    final title =
        TripSectionFields.clean(_title.text) ??
        (initial == null ? template.title : '');
    final list = initial == null
        ? template.build(
            tripId: widget.tripId,
            authorUid: widget.authorUid,
            title: title,
            isPrivate: _private,
          )
        : TripChecklist(
            id: initial.id,
            tripId: initial.tripId,
            createdByUid: initial.createdByUid,
            title: title,
            isPrivate: _private,
            template: initial.template,
            categories: initial.categories,
            entries: initial.entries,
          );
    return saveWith(
      problems: [
        for (final p in const TripChecklistCodec().problems(list))
          TripSectionLabels.problem(p, l10n, fieldLabel: (_) => l10n.noteTitle),
      ],
      save: () => widget.onSave(list),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templates = TripChecklistTemplates.all(l10n);
    return TripSectionEditorFrame(
      keyPrefix: 'checklist',
      title: widget.initial == null
          ? l10n.checklistAdd
          : l10n.checklistEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        if (widget.initial == null)
          TripSectionBlock(
            title: l10n.checklistTemplate,
            icon: Icons.auto_awesome_motion_outlined,
            children: [
              TripSectionChoices<String>(
                keyPrefix: 'checklist-template',
                values: [for (final t in templates) t.code],
                codeOf: (c) => c,
                labelOf: (c) => templates.firstWhere((t) => t.code == c).title,
                selected: _template,
                onChanged: (c) => setState(() => _template = c ?? _template),
              ),
            ],
          ),
        TripSectionBlock(
          title: l10n.checklistBlockList,
          icon: Icons.checklist_rounded,
          children: [
            TextField(
              key: const Key('checklist-title'),
              controller: _title,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(
                labelText: l10n.noteTitle,
                hintText: widget.initial == null
                    ? templates.firstWhere((t) => t.code == _template).title
                    : null,
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('checklist-private'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AmaterasuColors.accentBudget,
                value: _private,
                onChanged: _canChangePrivacy
                    ? (v) => setState(() => _private = v)
                    : null,
                title: Text(l10n.checklistPrivate),
                subtitle: Text(l10n.checklistPrivateHint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
