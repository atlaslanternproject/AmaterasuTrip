// Pannello dei filtri condiviso (nato negli alloggi): gruppi di etichette
// selezionabili con titolo, "Azzera filtri" in alto e "Fatto" in basso. Le
// scelte si applicano subito.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class AmaterasuFilterOption {
  const AmaterasuFilterOption({
    required this.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String key;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
}

class AmaterasuFilterGroup {
  const AmaterasuFilterGroup(this.title, this.options);

  final String title;
  final List<AmaterasuFilterOption> options;
}

/// Opens the sheet; [groupsOf] builds the groups for the current filter
/// and gets the function that applies a new one.
Future<void> showAmaterasuFilterSheet<F>(
  BuildContext context, {
  required String keyPrefix,
  required F initial,
  required ValueChanged<F> onChanged,
  ValueListenable<F>? listenable,
  required bool Function(F filter) isActive,
  required F Function(F filter) cleared,
  required List<AmaterasuFilterGroup> Function(F filter, ValueChanged<F> update)
  groupsOf,
}) {
  var filter = initial;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AmaterasuColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _Follow<F>(
      listenable: listenable,
      child: StatefulBuilder(
        builder: (context, setState) {
          if (listenable != null) filter = listenable.value;
          final l10n = AppLocalizations.of(context)!;
          void update(F next) {
            setState(() => filter = next);
            onChanged(next);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.filtersTitle,
                          style: const TextStyle(
                            color: AmaterasuColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        key: Key('$keyPrefix-sheet-clear'),
                        onPressed: isActive(filter)
                            ? () => update(cleared(filter))
                            : null,
                        child: Text(l10n.filtersClear),
                      ),
                    ],
                  ),
                  for (final group in groupsOf(filter, update)) ...[
                    _Title(group.title),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final option in group.options)
                          FilterChip(
                            key: Key(option.key),
                            avatar: option.icon == null
                                ? null
                                : Icon(
                                    option.icon,
                                    size: 16,
                                    color: AmaterasuColors.accentBudget,
                                  ),
                            label: Text(option.label),
                            selected: option.selected,
                            selectedColor: AmaterasuColors.accentBudget
                                .withValues(alpha: 0.25),
                            onSelected: (_) => option.onTap(),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: Key('$keyPrefix-sheet-done'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AmaterasuColors.accentBudget,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(l10n.filtersDone),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Rebuilds the sheet when [listenable] changes (or never, when null).
class _Follow<F> extends StatelessWidget {
  const _Follow({required this.listenable, required this.child});

  final ValueListenable<F>? listenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final source = listenable;
    if (source == null) return child;
    return ValueListenableBuilder<F>(
      valueListenable: source,
      builder: (_, _, _) => child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AmaterasuColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
