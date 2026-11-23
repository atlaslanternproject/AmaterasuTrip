// Parte di trip_shopping_editors.dart: editor di una voce della valigia
// (cosa, per chi, quantità).

part of 'trip_shopping_editors.dart';

class TripPackingEditor extends StatefulWidget {
  const TripPackingEditor({
    super.key,
    required this.tripId,
    required this.authorUid,
    required this.memberNames,
    required this.onSave,
    this.initial,
  });

  final String tripId;
  final String authorUid;
  final Map<String, String> memberNames;
  final Future<void> Function(TripPackingItem item) onSave;
  final TripPackingItem? initial;

  @override
  State<TripPackingEditor> createState() => _TripPackingEditorState();
}

class _TripPackingEditorState extends State<TripPackingEditor>
    with TripSectionEditorSave {
  late final _i = widget.initial;
  late final _name = TextEditingController(text: _i?.name);
  late final _quantity = TextEditingController(
    text: _i?.quantity?.toString() ?? '',
  );
  late String? _person = _i?.personUid;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final l10n = AppLocalizations.of(context)!;
    final quantity = _quantity.text.trim();
    final item = TripPackingItem(
      id: _i?.id ?? '',
      tripId: widget.tripId,
      createdByUid: _i?.createdByUid ?? widget.authorUid,
      name: _name.text.trim(),
      personUid: _person,
      quantity: quantity.isEmpty ? null : (int.tryParse(quantity) ?? 0),
      packed: _i?.packed ?? false,
    );
    return saveWith(
      problems: [
        for (final p in const TripPackingItemCodec().problems(item))
          TripSectionLabels.problem(
            p,
            l10n,
            fieldLabel: (_) => l10n.shoppingName,
            other: (_) => l10n.packingErrQuantity,
          ),
      ],
      save: () => widget.onSave(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TripSectionEditorFrame(
      keyPrefix: 'packing',
      title: _i == null
          ? l10n.packingEditorNewTitle
          : l10n.packingEditorEditTitle,
      messages: messages,
      saving: saving,
      onSave: _save,
      children: [
        TripSectionBlock(
          title: l10n.packingBlockItem,
          icon: Icons.luggage_outlined,
          children: [
            TextField(
              key: const Key('packing-name'),
              controller: _name,
              maxLength: TripSectionFields.nameMax,
              decoration: InputDecoration(labelText: l10n.shoppingName),
            ),
            Text(l10n.packingFor),
            const SizedBox(height: 6),
            _personChoice(
              'packing-for',
              widget.memberNames,
              _person,
              (v) => setState(() => _person = v),
            ),
            TextField(
              key: const Key('packing-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              maxLength: 2,
              decoration: InputDecoration(labelText: l10n.packingQuantity),
            ),
          ],
        ),
      ],
    );
  }
}
