// Campo "Link utili" comune, con lo stesso aspetto e comportamento di
// quello della bucket list: una riga per link (con "Rimuovi link"), sempre
// almeno una riga vuota, pulsante "Aggiungi un link" fino al massimo.
// Lo stato (AmaterasuLinksDraft) dà i link puliti e quelli non validi.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_web_link.dart';

class AmaterasuLinksDraft {
  AmaterasuLinksDraft(List<String> initial, {this.max = 10})
    : rows = [
        for (final link in initial) TextEditingController(text: link),
        if (initial.isEmpty) TextEditingController(),
      ];

  final int max;
  final List<TextEditingController> rows;

  /// Filled links, trimmed, in order.
  List<String> get links => [
    for (final row in rows)
      if (row.text.trim().isNotEmpty) row.text.trim(),
  ];

  bool get valid =>
      links.length <= max && links.every(AmaterasuWebLink.isValid);

  void add() => rows.add(TextEditingController());

  void removeAt(int index) {
    final removed = rows.removeAt(index);
    // Disposed after the frame that still shows it.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
    if (rows.isEmpty) rows.add(TextEditingController());
  }

  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
  }
}

class AmaterasuLinksField extends StatelessWidget {
  const AmaterasuLinksField({
    super.key,
    required this.keyPrefix,
    required this.draft,
    required this.onChanged,
  });

  final String keyPrefix;
  final AmaterasuLinksDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < draft.rows.length; i++) ...[
          Row(
            key: ObjectKey(draft.rows[i]),
            children: [
              Expanded(
                child: TextField(
                  key: Key('$keyPrefix-link-$i'),
                  controller: draft.rows[i],
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.commonLinkNumber(i + 1),
                    prefixIcon: const Icon(Icons.link_outlined),
                  ),
                ),
              ),
              IconButton(
                key: Key('$keyPrefix-link-remove-$i'),
                tooltip: l10n.commonLinkRemove,
                onPressed: () {
                  draft.removeAt(i);
                  onChanged();
                },
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AmaterasuColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmaterasuSpacing.sm),
        ],
        OutlinedButton.icon(
          key: Key('$keyPrefix-link-add'),
          onPressed: draft.rows.length >= draft.max
              ? null
              : () {
                  draft.add();
                  onChanged();
                },
          icon: const Icon(Icons.add_link),
          label: Text(l10n.commonLinkAdd),
        ),
      ],
    );
  }
}
