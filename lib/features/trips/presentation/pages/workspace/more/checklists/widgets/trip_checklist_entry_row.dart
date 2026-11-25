// Una voce della checklist in linea: casella da spuntare, testo (toccandolo
// si modifica), casella della quantità in cui si scrive il numero e
// assegnatario (username).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_link_chip.dart';
import 'package:flutter/services.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/checklists/models/trip_checklist.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripChecklistEntryRow extends StatefulWidget {
  const TripChecklistEntryRow({
    super.key,
    required this.entry,
    required this.assigneeName,
    required this.onToggle,
    required this.onQuantity,
    required this.onOpen,
  });

  final TripChecklistEntry entry;
  final String? assigneeName;
  final VoidCallback onToggle;
  final ValueChanged<int?> onQuantity;
  final VoidCallback onOpen;

  @override
  State<TripChecklistEntryRow> createState() => _TripChecklistEntryRowState();
}

class _TripChecklistEntryRowState extends State<TripChecklistEntryRow> {
  late final _quantity = TextEditingController(
    text: widget.entry.quantity?.toString() ?? '',
  );

  @override
  void didUpdateWidget(TripChecklistEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.entry.quantity?.toString() ?? '';
    if (oldWidget.entry.quantity != widget.entry.quantity &&
        _quantity.text != text) {
      _quantity.text = text;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _saveQuantity() {
    final value = int.tryParse(_quantity.text.trim());
    final quantity = value == null || value < 1 ? null : value.clamp(1, 999);
    if (quantity != widget.entry.quantity) widget.onQuantity(quantity);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = widget.entry;
    final id = entry.id;
    final name = widget.assigneeName;
    return Row(
      children: [
        Checkbox(
          key: Key('checklist-check-$id'),
          value: entry.done,
          activeColor: AmaterasuColors.accentBudget,
          onChanged: (_) => widget.onToggle(),
        ),
        Expanded(
          child: InkWell(
            key: Key('checklist-entry-$id'),
            onTap: widget.onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.text,
                    style: TextStyle(
                      color: entry.done
                          ? AmaterasuColors.textMuted
                          : AmaterasuColors.textPrimary,
                      fontSize: 14,
                      decoration: entry.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (name != null)
                    Text(
                      name,
                      style: const TextStyle(
                        color: AmaterasuColors.accentGold,
                        fontSize: 12,
                      ),
                    ),
                  if (entry.usefulLinks.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final link in entry.usefulLinks)
                          AmaterasuLinkChip(link: link),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Focus(
            onFocusChange: (focused) {
              if (!focused) _saveQuantity();
            },
            child: TextField(
              key: Key('checklist-qty-$id'),
              controller: _quantity,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onSubmitted: (_) => _saveQuantity(),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.checklistQuantityHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
