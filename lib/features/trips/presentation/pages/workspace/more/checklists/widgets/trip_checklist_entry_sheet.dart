// Modifica di una voce della checklist nel pannello condiviso: testo,
// categoria, quantità, assegnatario (username) ed eliminazione con doppia
// conferma. Restituisce la voce cambiata, "elimina" oppure niente.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_confirm.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Result of the sheet: the edited entry, or [delete] true.
typedef TripChecklistEntryEdit = ({TripChecklistEntry? entry, bool delete});

Future<TripChecklistEntryEdit?> showTripChecklistEntrySheet(
  BuildContext context, {
  required TripChecklistEntry entry,
  required List<String> categories,
  required Map<String, String> memberNames,
}) => showAmaterasuSheet<TripChecklistEntryEdit>(
  context,
  builder: (_) => _EntrySheet(
    entry: entry,
    categories: categories,
    memberNames: memberNames,
  ),
);

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({
    required this.entry,
    required this.categories,
    required this.memberNames,
  });

  final TripChecklistEntry entry;
  final List<String> categories;
  final Map<String, String> memberNames;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  late final _text = TextEditingController(text: widget.entry.text);
  late final _quantity = TextEditingController(
    text: widget.entry.quantity?.toString() ?? '',
  );
  late String _category = widget.entry.category;
  late String? _assignee = widget.entry.assigneeUid;

  @override
  void dispose() {
    _text.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _save() {
    final quantity = int.tryParse(_quantity.text.trim());
    final entry = widget.entry.copyWith(
      text: _text.text.trim(),
      category: _category,
      quantity: quantity,
      clearQuantity: quantity == null,
      assigneeUid: _assignee,
      clearAssignee: _assignee == null,
    );
    if (TripChecklistCodec.entryProblems(entry).isNotEmpty) return;
    Navigator.pop<TripChecklistEntryEdit>(context, (
      entry: entry,
      delete: false,
    ));
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmAmaterasuAction(
      context,
      title: l10n.checklistDeleteEntry,
      body: widget.entry.text,
      confirmLabel: l10n.sectionsDelete,
      destructive: true,
      keyPrefix: 'checklist-entry-delete',
    );
    if (ok && mounted) {
      Navigator.pop<TripChecklistEntryEdit>(context, (
        entry: null,
        delete: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('checklist-entry-text'),
            controller: _text,
            maxLength: TripChecklistCodec.textMax,
            decoration: InputDecoration(labelText: l10n.checklistEntry),
          ),
          TextField(
            key: const Key('checklist-entry-quantity'),
            controller: _quantity,
            keyboardType: TextInputType.number,
            maxLength: 3,
            decoration: InputDecoration(labelText: l10n.packingQuantity),
          ),
          Text(l10n.sectionsFilterCategory),
          const SizedBox(height: 6),
          TripSectionChoices<String>(
            keyPrefix: 'checklist-entry-category',
            values: widget.categories,
            codeOf: (c) => c,
            labelOf: (c) => c,
            selected: _category,
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: 12),
          Text(l10n.checklistAssignee),
          const SizedBox(height: 6),
          TripSectionChoices<String>(
            keyPrefix: 'checklist-entry-assignee',
            values: widget.memberNames.keys.toList(),
            codeOf: (uid) => uid,
            labelOf: (uid) => widget.memberNames[uid] ?? uid,
            selected: _assignee,
            allowNone: true,
            onChanged: (uid) => setState(() => _assignee = uid),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AmaterasuButton.destructive(
                key: const Key('checklist-entry-remove'),
                label: l10n.sectionsDelete,
                onPressed: _delete,
              ),
              AmaterasuButton.primary(
                key: const Key('checklist-entry-save'),
                label: l10n.sectionsSave,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
