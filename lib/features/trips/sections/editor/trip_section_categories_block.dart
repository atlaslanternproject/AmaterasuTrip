// Blocco "Categorie personalizzate" degli editor delle sezioni (Extra D):
// come la categoria "Altro" della bucket list (scrivi una categoria o
// tocca una di quelle già usate nel viaggio), ma con selezione multipla
// fino a 5. Le categorie del viaggio si leggono una volta all'apertura.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../data/trip_section_categories_store.dart';
import '../models/trip_section_categories.dart';
import 'trip_section_block.dart';

class TripSectionCategoriesDraft {
  TripSectionCategoriesDraft(List<String> initial) : labels = [...initial];

  final List<String> labels;
  final text = TextEditingController();

  void dispose() => text.dispose();
}

class TripSectionCategoriesBlock extends ConsumerStatefulWidget {
  const TripSectionCategoriesBlock({
    super.key,
    required this.keyPrefix,
    required this.tripId,
    required this.draft,
    required this.onChanged,
  });

  final String keyPrefix;
  final String tripId;
  final TripSectionCategoriesDraft draft;
  final VoidCallback onChanged;

  @override
  ConsumerState<TripSectionCategoriesBlock> createState() =>
      _TripSectionCategoriesBlockState();
}

class _TripSectionCategoriesBlockState
    extends ConsumerState<TripSectionCategoriesBlock> {
  late final Future<List<String>> _known = ref
      .read(tripSectionCategoriesStoreProvider)
      .labels(widget.tripId)
      .catchError((Object _) => const <String>[]);

  List<String> get _labels => widget.draft.labels;

  bool _has(String label) => _labels.any(
    (l) => l.toLowerCase() == TripSectionCategories.clean(label).toLowerCase(),
  );

  void _add(String label) {
    final clean = TripSectionCategories.clean(label);
    if (clean.isEmpty ||
        clean.length > TripSectionCategories.labelMax ||
        _labels.length >= TripSectionCategories.max ||
        _has(clean)) {
      return;
    }
    setState(() {
      _labels.add(clean);
      widget.draft.text.clear();
    });
    ref.read(tripSectionCategoriesStoreProvider).add(widget.tripId, clean);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.keyPrefix;
    final full = _labels.length >= TripSectionCategories.max;
    return TripSectionBlock(
      title: l10n.sectionsCategories,
      icon: Icons.label_outline_rounded,
      initiallyOpen: _labels.isNotEmpty,
      children: [
        if (_labels.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in _labels)
                InputChip(
                  key: Key('$p-category-$label'),
                  label: Text(label),
                  onDeleted: () {
                    setState(() => _labels.remove(label));
                    widget.onChanged();
                  },
                ),
            ],
          ),
        const SizedBox(height: 8),
        TextField(
          key: Key('$p-category-text'),
          controller: widget.draft.text,
          enabled: !full,
          maxLength: TripSectionCategories.labelMax,
          onSubmitted: _add,
          decoration: InputDecoration(
            labelText: full
                ? l10n.sectionsCategoriesFull
                : l10n.sectionsCategoryNew,
            suffixIcon: IconButton(
              key: Key('$p-category-add'),
              tooltip: l10n.sectionsCategoryAdd,
              onPressed: full ? null : () => _add(widget.draft.text.text),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        FutureBuilder(
          future: _known,
          builder: (context, snap) {
            final known = [
              for (final l in snap.data ?? const <String>[])
                if (!_has(l)) l,
            ];
            if (known.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sectionsCategoriesUsed,
                  style: const TextStyle(
                    color: AmaterasuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in known.take(12))
                      ActionChip(
                        key: Key('$p-category-known-$label'),
                        label: Text(label),
                        onPressed: full ? null : () => _add(label),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
