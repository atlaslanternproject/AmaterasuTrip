// Scelte a etichette per gli editor delle sezioni: un valore tra tanti
// (o nessuno) e viaggiatori del viaggio da aggiungere o togliere.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

/// One choice among [values] as chips; with [allowNone] it can be removed.
class TripSectionChoices<T> extends StatelessWidget {
  const TripSectionChoices({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.codeOf,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.iconOf,
    this.allowNone = false,
  });

  final String keyPrefix;
  final List<T> values;
  final String Function(T value) codeOf;
  final String Function(T value) labelOf;
  final IconData Function(T value)? iconOf;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final value in values)
        ChoiceChip(
          key: Key('$keyPrefix-${codeOf(value)}'),
          avatar: iconOf == null
              ? null
              : Icon(
                  iconOf!(value),
                  size: 16,
                  color: AmaterasuColors.accentBudget,
                ),
          label: Text(labelOf(value)),
          selected: selected == value,
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (on) {
            if (on) {
              onChanged(value);
            } else if (allowNone) {
              onChanged(null);
            }
          },
        ),
    ],
  );
}

/// Trip members as chips: tap to add or remove.
class TripSectionMembers extends StatelessWidget {
  const TripSectionMembers({
    super.key,
    required this.keyPrefix,
    required this.memberNames,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final Map<String, String> memberNames;
  final Set<String> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final entry in memberNames.entries)
        FilterChip(
          key: Key('$keyPrefix-${entry.key}'),
          label: Text(entry.value),
          selected: selected.contains(entry.key),
          selectedColor: AmaterasuColors.accentBudget.withValues(alpha: 0.25),
          onSelected: (on) {
            on ? selected.add(entry.key) : selected.remove(entry.key);
            onChanged();
          },
        ),
    ],
  );
}
