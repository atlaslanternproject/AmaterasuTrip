// Editor dello shopping (cosa, per chi: viaggiatore e/o destinatario
// libero, priorità, dove, comprato, budget stimato, prezzo reale, note)
// nella cornice comune delle sezioni. Chi l'ha comprato si salva da solo.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_links_block.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_priority.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_codecs.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_shopping_draft.dart';

class TripShoppingEditor extends StatefulWidget {
  const TripShoppingEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.memberNames,
    required this.defaultCurrency,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Map<String, String> memberNames;
  final String defaultCurrency;
  final Future<void> Function(TripShoppingItem item) onSave;
  final TripShoppingItem? initial;

  @override
  State<TripShoppingEditor> createState() => _TripShoppingEditorState();
}

class _TripShoppingEditorState extends State<TripShoppingEditor>
    with TripSectionEditorSave {
  late final _d = TripShoppingDraft(widget.initial, widget.defaultCurrency);

  @override
  void dispose() {
    _d.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final item = _d.toItem(tripId: widget.tripId, authorUid: widget.authorUid);
    return saveWith(
      problems: [
        for (final p in const TripShoppingItemCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.shoppingName,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = _d;
    void changed() => setState(() {});
    return TripSectionEditorFrame(
      keyPrefix: 'shopping',
      title: d.isNew
          ? l10n.shoppingEditorNewTitle
          : l10n.shoppingEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.shoppingBlockItem,
          icon: Icons.shopping_bag_outlined,
          children: [
            TextField(
              key: const Key('shopping-name'),
              controller: d.name,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.shoppingName),
            ),
            Text(l10n.shoppingFor),
            const SizedBox(height: 6),
            // Traveler choice: tap again to remove it.
            TripSectionChoices<String>(
              keyPrefix: 'shopping-for',
              values: widget.memberNames.keys.toList(),
              codeOf: (uid) => uid,
              labelOf: (uid) => widget.memberNames[uid] ?? uid,
              selected: d.forUid,
              allowNone: true,
              onChanged: (v) => setState(() => d.forUid = v),
            ),
            TextField(
              key: const Key('shopping-for-text'),
              controller: d.forText,
              maxLength: TripSectionFields.shortMax,
              decoration: InputDecoration(
                labelText: l10n.shoppingForText,
                helperText: l10n.shoppingForTextHint,
              ),
            ),
            Text(l10n.shoppingPriority),
            const SizedBox(height: 6),
            TripSectionChoices<String>(
              keyPrefix: 'shopping-priority',
              values: TripSectionPriority.levels,
              codeOf: (p) => p,
              labelOf: (p) => p,
              selected: d.priority,
              allowNone: true,
              onChanged: (p) => setState(() => d.priority = p),
            ),
            TextField(
              key: const Key('shopping-where'),
              controller: d.where,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.shoppingWhere),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('shopping-bought'),
                contentPadding: EdgeInsets.zero,
                value: d.bought,
                onChanged: (v) => setState(() => d.bought = v),
                title: Text(l10n.shoppingBought),
              ),
            ),
          ],
        ),
        TripSectionBlock(
          title: l10n.sectionsBlockCost,
          icon: Icons.payments_outlined,
          children: [
            TripSectionCostField(
              keyPrefix: 'shopping-budget',
              draft: d.budget,
              onChanged: changed,
              label: l10n.shoppingBudget,
            ),
            const SizedBox(height: 8),
            TripSectionCostField(
              keyPrefix: 'shopping-price',
              draft: d.price,
              onChanged: changed,
              label: l10n.shoppingPrice,
            ),
            TextField(
              key: const Key('shopping-notes'),
              controller: d.notes,
              minLines: 2,
              maxLines: 5,
              maxLength: TripSectionFields.notesMax,
              decoration: InputDecoration(labelText: l10n.sectionsNotes),
            ),
          ],
        ),
        TripSectionLinksBlock(
          keyPrefix: 'shopping',
          draft: _d.links,
          onChanged: changed,
        ),
      ],
    );
  }
}
