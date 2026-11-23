// Editor dello shopping (cosa, per chi, dove, comprato, budget stimato,
// prezzo reale, note) e della valigia (cosa, per chi, quantità) nella
// cornice comune delle sezioni.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/trips/sections/editor/trip_section_block.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_chips.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_cost_field.dart';
import 'package:amaterasutrip/features/trips/sections/editor/trip_section_editor_frame.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_labels.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_packing_item.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_codecs.dart';
import 'package:amaterasutrip/features/trips/shopping/models/trip_shopping_item.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

part 'trip_packing_editor.dart';

/// Traveler choice: tap again to remove it.
Widget _personChoice(
  String keyPrefix,
  Map<String, String> names,
  String? selected,
  ValueChanged<String?> onChanged,
) => TripSectionChoices<String>(
  keyPrefix: keyPrefix,
  values: names.keys.toList(),
  codeOf: (uid) => uid,
  labelOf: (uid) => names[uid] ?? uid,
  selected: selected,
  allowNone: true,
  onChanged: onChanged,
);

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
  late final _i = widget.initial;
  late final _name = TextEditingController(text: _i?.name);
  late final _where = TextEditingController(text: _i?.where);
  late final _notes = TextEditingController(text: _i?.notes);
  late String? _forUid = _i?.forUid;
  late bool _bought = _i?.bought ?? false;
  late final _budget = TripSectionCostDraft(
    minorUnits: _i?.estimatedCostMinorUnits,
    currency: _i?.estimatedCostCurrency,
    fallback: widget.defaultCurrency,
  );
  late final _price = TripSectionCostDraft(
    minorUnits: _i?.actualCostMinorUnits,
    currency: _i?.actualCostCurrency,
    fallback: widget.defaultCurrency,
  );

  @override
  void dispose() {
    for (final c in [_name, _where, _notes]) {
      c.dispose();
    }
    _budget.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final item = TripShoppingItem(
      id: _i?.id ?? '',
      tripId: widget.tripId,
      createdByUid: _i?.createdByUid ?? widget.authorUid,
      name: _name.text.trim(),
      forUid: _forUid,
      where: TripSectionFields.clean(_where.text),
      bought: _bought,
      estimatedCostMinorUnits: _budget.minorUnits,
      estimatedCostCurrency: _budget.savedCurrency,
      actualCostMinorUnits: _price.minorUnits,
      actualCostCurrency: _price.savedCurrency,
      notes: TripSectionFields.clean(_notes.text),
      expenseId: _i?.expenseId,
    );
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
    void changed() => setState(() {});
    return TripSectionEditorFrame(
      keyPrefix: 'shopping',
      title: _i == null
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
              controller: _name,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.shoppingName),
            ),
            Text(l10n.shoppingFor),
            const SizedBox(height: 6),
            _personChoice(
              'shopping-for',
              widget.memberNames,
              _forUid,
              (v) => setState(() => _forUid = v),
            ),
            TextField(
              key: const Key('shopping-where'),
              controller: _where,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.shoppingWhere),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const Key('shopping-bought'),
                contentPadding: EdgeInsets.zero,
                value: _bought,
                onChanged: (v) => setState(() => _bought = v),
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
              draft: _budget,
              onChanged: changed,
              label: l10n.shoppingBudget,
            ),
            const SizedBox(height: 8),
            TripSectionCostField(
              keyPrefix: 'shopping-price',
              draft: _price,
              onChanged: changed,
              label: l10n.shoppingPrice,
            ),
            TextField(
              key: const Key('shopping-notes'),
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              maxLength: TripSectionFields.notesMax,
              decoration: InputDecoration(labelText: l10n.sectionsNotes),
            ),
          ],
        ),
      ],
    );
  }
}
