// Una categoria della checklist a tendina: riepilogo "3/8", barra di
// avanzamento, voci in linea (riordinabili trascinandole quando non ci sono
// filtri) e campo per aggiungere una voce al volo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/inputs/amaterasu_fold_section.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist_codec.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_checklist_entry_row.dart';
import 'trip_checklist_progress.dart';

class TripChecklistCategory extends StatefulWidget {
  const TripChecklistCategory({
    super.key,
    required this.name,
    required this.all,
    required this.shown,
    required this.nameOf,
    required this.onToggle,
    required this.onQuantity,
    required this.onOpen,
    required this.onAdd,
    required this.onReorder,
  });

  final String name;

  /// Every entry of the category (for the progress) and the filtered ones.
  final List<TripChecklistEntry> all;
  final List<TripChecklistEntry> shown;
  final String? Function(String? uid) nameOf;
  final void Function(TripChecklistEntry entry) onToggle;
  final void Function(TripChecklistEntry entry, int? quantity) onQuantity;
  final void Function(TripChecklistEntry entry) onOpen;
  final void Function(String text) onAdd;

  /// Entry ids in the new order (only without filters).
  final void Function(List<String> ids)? onReorder;

  @override
  State<TripChecklistCategory> createState() => _TripChecklistCategoryState();
}

class _TripChecklistCategoryState extends State<TripChecklistCategory> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  void _add() {
    final text = _new.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _new.clear();
  }

  Widget _row(TripChecklistEntry e) => TripChecklistEntryRow(
    key: ValueKey(e.id),
    entry: e,
    assigneeName: widget.nameOf(e.assigneeUid),
    onToggle: () => widget.onToggle(e),
    onQuantity: (q) => widget.onQuantity(e, q),
    onOpen: () => widget.onOpen(e),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = widget.all.where((e) => e.done).length;
    final reorder = widget.onReorder;
    return AmaterasuFoldSection(
      key: Key('checklist-category-${widget.name}'),
      title: widget.name,
      icon: Icons.checklist_rounded,
      summary: l10n.checklistDoneOf(done, widget.all.length),
      children: [
        TripChecklistProgress(done: done, total: widget.all.length),
        const SizedBox(height: 4),
        if (reorder == null)
          for (final e in widget.shown) _row(e)
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: true,
            onReorderItem: (from, to) {
              final ids = [for (final e in widget.shown) e.id];
              ids.insert(to, ids.removeAt(from));
              reorder(ids);
            },
            children: [for (final e in widget.shown) _row(e)],
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: Key('checklist-add-${widget.name}'),
                controller: _new,
                maxLength: TripChecklistCodec.textMax,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: l10n.checklistAddEntry,
                  counterText: '',
                ),
              ),
            ),
            IconButton(
              key: Key('checklist-add-go-${widget.name}'),
              tooltip: l10n.checklistAddEntry,
              onPressed: _add,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
